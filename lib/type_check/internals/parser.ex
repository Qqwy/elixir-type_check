defmodule TypeCheck.Internals.Parser do
  @moduledoc """
  The parser for the default Elixir/Erlang `@spec`.

  Experimental!
  """

  alias TypeCheck.Builtin, as: B

  defmodule Context do
    @moduledoc """
    Container for context information of convert/2.

    Params:

    * `default`: the default type to use when the actual type cannot be resolved.
    * `vars`: concrette types for type variables, used for parsing generic types.
    * `module`: the module of the currently parsed type, use to resolve user types.
    * `max_depth`: how deeply remote types should be resolved,
      used to prevent infinite recursion for recursive types.
    """
    defstruct [:default, :vars, :module, :max_depth]

    @type t :: %Context{
            default: TypeCheck.Type.t(),
            vars: %{String.t() => TypeCheck.Type.t()},
            module: module(),
            max_depth: non_neg_integer()
          }

    def default(), do: %__MODULE__{default: B.any(), vars: %{}, module: nil, max_depth: 5}
  end

  @opaque raw :: {atom | nil, list, list | :any}

  @doc """
  Extract raw spec for the given MFA.

      iex> import TypeCheck.Internals.Parser
      iex> {:ok, _} = fetch_spec(Kernel, :node, 1)
  """
  @spec fetch_spec(module() | binary() | list(), atom(), arity()) ::
          {:error, String.t()} | {:ok, [raw]}
  def fetch_spec(module, function, arity) when is_atom(module) or is_binary(module) do
    with {:module, _} <- ensure_loaded(module),
         {:ok, specs} <- Code.Typespec.fetch_specs(module) do
      fetch_spec(specs, function, arity)
    else
      {:error, reason} when is_atom(reason) ->
        {:error, "could not load module #{inspect(module)} due to reason #{inspect(reason)}"}

      :error ->
        {:error, "cannot fetch specs from the module"}
    end
  end

  def fetch_spec(specs, function, arity) when is_list(specs) do
    case specs |> Enum.find(fn {func, _spec} -> func == {function, arity} end) do
      {_, specs} -> {:ok, specs}
      nil -> {:error, "cannot find spec for function"}
    end
  end

  @doc """
  Fetch raw type definition for the given type with the given number of generic variables.
  """
  @spec fetch_type(module() | binary(), atom(), arity()) ::
          {:error, String.t()} | {:ok, raw, [atom()]}
  def fetch_type(module, type, arity) do
    case fetch_types(module, type) do
      {:ok, []} -> {:error, "cannot find type with the given name"}
      {:ok, types} -> fetch_type(types, arity)
      {:error, err} -> {:error, err}
    end
  end

  @spec fetch_type(list(), arity()) :: {:error, String.t()} | {:ok, raw, [atom()]}
  defp fetch_type(types, arity) when is_list(types) do
    case types |> Enum.find(fn {_, {_, _, vars}} -> length(vars) == arity end) do
      {_, {_, spec, vars}} ->
        var_names = Enum.map(vars, fn {:var, _, name} -> name end)
        {:ok, spec, var_names}

      nil ->
        {:error, "cannot find type with the given arity"}
    end
  end

  @doc """
  Get list of all types from the module matching the given name.

  If no types found, empty list is returned.
  It is possible for list to contain multiple types if there are multiple type
  definitions with the same name but different amount of generic arguments.
  """
  @spec fetch_types(module() | binary() | [raw], atom()) :: {:error, String.t()} | {:ok, [raw]}
  def fetch_types(module, type) when is_atom(module) or is_binary(module) do
    with {:module, _} <- ensure_loaded(module),
         {:ok, types} <- Code.Typespec.fetch_types(module) do
      fetch_types(types, type)
    else
      {:error, reason} when is_atom(reason) ->
        {:error, "could not load module #{inspect(module)} due to reason #{inspect(reason)}"}

      :error ->
        {:error, "cannot fetch types from the module"}
    end
  end

  def fetch_types(types, type) when is_list(types) do
    filtered = types |> Enum.filter(fn {_, {name, _, _}} -> name == type end)
    {:ok, filtered}
  end

  # A safe version of `Code.ensure_loaded/1` that ignores raw bytecode.
  @spec ensure_loaded(module() | binary()) :: {:module, module()} | {:error, atom()}
  defp ensure_loaded(module) when is_atom(module), do: Code.ensure_loaded(module)
  defp ensure_loaded(_), do: {:module, :bytecode}

  @doc """
  Extract module name, function name, and arguments from quoted expression of a function call.

  ## Examples

      iex> import TypeCheck.Internals.Parser
      iex> ast_to_mfa(quote do: abs(1))
      {Kernel, :abs, [1]}
      iex> ast_to_mfa(quote do: Kernel.abs(1))
      {Kernel, :abs, [1]}
      iex> ast_to_mfa(quote do: Date.diff(1, 2))
      {Date, :diff, [1, 2]}
      iex> alias Date, as: D
      iex> ast_to_mfa(quote do: D.diff(1, 2))
      {Date, :diff, [1, 2]}
  """
  @spec ast_to_mfa(Macro.t()) :: {module(), atom(), [Macro.t()]} | {:error, String.t()}
  def ast_to_mfa({func, [context: _, import: module], args}) do
    {module, func, args}
  end

  def ast_to_mfa({target, _, args}) do
    case target do
      {:., _, [{:__aliases__, [alias: false], [mod]}, func]} -> {elixir_module(mod), func, args}
      {:., _, [{:__aliases__, [alias: mod], _}, func]} -> {mod, func, args}
      {:., _, [{:__aliases__, _, [mod]}, func]} -> {elixir_module(mod), func, args}
      {:., _, [mod, func]} when is_atom(mod) -> {mod, func, args}
      _ -> {:error, "cannot infer function"}
    end
  end

  def ast_to_mfa(_), do: {:error, "not a function call"}

  @spec elixir_module(module()) :: module()
  defp elixir_module(module), do: String.to_atom("Elixir.#{module}")

  @doc """
  Convert the raw spec extracted by `fetch_spec/3` into type_check type.

  The function is optimistic. If the type is not known, it assumes `any()`.

      iex> import TypeCheck.Builtin
      iex> import TypeCheck.Internals.Parser
      iex> {:ok, spec} = fetch_spec(Kernel, :is_atom, 1)
      iex> expected = function([term()], boolean())
      iex> ^expected = convert(spec)
  """
  @spec convert(raw | [raw]) :: TypeCheck.Type.t()
  def convert(type), do: convert(type, Context.default())

  @spec convert(raw | [raw], Context.t()) :: TypeCheck.Type.t()

  def convert(types, ctx) when is_list(types),
    do: types |> Enum.map(&convert(&1, ctx)) |> B.one_of()

  def convert({:type, _, name, vars}, ctx), do: convert_type(name, vars, ctx)
  def convert({:atom, _, val}, _), do: B.literal(val)
  def convert({:integer, _, val}, _), do: B.literal(val)
  def convert({:ann_type, _, [_var, t]}, ctx), do: convert(t, ctx)
  def convert({:var, _, name}, ctx), do: Map.get(ctx.vars, name, ctx.default)
  def convert({:user_type, _, _}, ctx = %{module: nil}), do: ctx.default

  def convert({:user_type, _, type, vars}, ctx),
    do: convert_remote_type(ctx.module, type, vars, ctx)

  def convert({:remote_type, _, [{:atom, _, module}, {:atom, _, type}, vars]}, ctx),
    do: convert_remote_type(module, type, vars, ctx)

  def convert(_, ctx), do: ctx.default

  @spec convert_remote_type(module(), atom(), [raw], Context.t()) :: TypeCheck.Type.t()
  defp convert_remote_type(_, _, _, ctx = %{max_depth: 0}), do: ctx.default

  defp convert_remote_type(module, type, vars, ctx) do
    case fetch_type(module, type, length(vars)) do
      {:ok, spec, var_names} ->
        # convert values from raw spec to type_check types
        vars = Enum.map(vars, &convert(&1, ctx))
        # add new key-value pairs into existing vars
        vars = Enum.zip(var_names, vars) |> Map.new()
        vars = Map.merge(ctx.vars, vars)
        ctx = %{ctx | vars: vars, module: module, max_depth: ctx.max_depth - 1}
        convert(spec, ctx)

      {:error, _} ->
        ctx.default
    end
  end

  @spec convert_type(atom() | nil, list() | :any, Context.t()) :: TypeCheck.Type.t()
  # basic types
  defp convert_type(:any, [], _), do: B.any()
  defp convert_type(:atom, [], _), do: B.atom()
  defp convert_type(:boolean, [], _), do: B.boolean()
  defp convert_type(:pid, [], _), do: B.pid()
  defp convert_type(:no_return, [], _), do: B.none()
  defp convert_type(:none, [], _), do: B.none()
  defp convert_type(:reference, [], _), do: B.reference()
  defp convert_type(:port, [], _), do: B.port()

  # bitstrings
  defp convert_type(:binary, [], _), do: B.binary()

  defp convert_type(:binary, [{:integer, _, prefix}, {:integer, _, unit}], _) do
    if unit == 0 do
      B.sized_bitstring(prefix)
    else
      B.sized_bitstring(prefix, unit)
    end
  end

  defp convert_type(:bitstring, [], _), do: B.bitstring()

  # numbers
  defp convert_type(:float, [], _), do: B.float()
  defp convert_type(:integer, [], _), do: B.integer()
  defp convert_type(:neg_integer, [], _), do: B.neg_integer()
  defp convert_type(:non_neg_integer, [], _), do: B.non_neg_integer()
  defp convert_type(:number, [], _), do: B.number()
  defp convert_type(:pos_integer, [], _), do: B.pos_integer()

  defp convert_type(:range, [{:integer, _, left}, {:integer, _, right}], _),
    do: B.range(left, right)

  # aliases
  defp convert_type(:term, [], _), do: B.term()
  defp convert_type(:arity, [], _), do: B.arity()
  defp convert_type(:mfa, [], _), do: B.mfa()
  defp convert_type(:module, [], _), do: B.module()
  defp convert_type(:nonempty_binary, [], _), do: B.nonempty_binary()
  defp convert_type(:nonempty_bitstring, [], _), do: B.nonempty_bitstring()
  defp convert_type(:byte, [], _), do: B.byte()
  defp convert_type(:char, [], _), do: B.char()
  defp convert_type(:node, [], _), do: B.atom()
  defp convert_type(:string, [], _), do: B.charlist()

  # shothands for generics
  defp convert_type(:fun, [], _), do: B.function()
  defp convert_type(:function, [], _), do: B.function()

  defp convert_type(:fun, [{:type, _, :any}, ret_type], ctx),
    do: B.function(convert(ret_type, ctx))

  defp convert_type(:list, [], _), do: B.list()
  # empty list
  defp convert_type(nil, [], _), do: B.list()
  defp convert_type(:map, :any, _), do: B.map()
  defp convert_type(:map, [], _), do: B.fixed_map([])
  defp convert_type(:nonempty_list, [], _), do: B.nonempty_list()

  defp convert_type(:nonempty_maybe_improper_list, [], _),
    do: B.maybe_improper_list(B.any(), B.any())

  defp convert_type(:maybe_improper_list, [], _), do: B.maybe_improper_list(B.any(), B.any())
  defp convert_type(:tuple, :any, _), do: B.tuple()

  # generics
  defp convert_type(:fun, [{:type, _, :product, arg_types}, ret_type], ctx),
    do: B.function(Enum.map(arg_types, &convert(&1, ctx)), convert(ret_type, ctx))

  defp convert_type(:bounded_fun, [t, vars], ctx) do
    vars =
      vars
      |> Enum.map(fn {:type, _, :constraint, [{:atom, _, :is_subtype}, [{:var, _, name}, type]]} ->
        {name, convert(type, ctx)}
      end)
      |> Map.new()

    vars = Map.merge(ctx.vars, vars)
    convert(t, %{ctx | vars: vars})
  end

  defp convert_type(:list, [t], ctx), do: B.list(convert(t, ctx))

  defp convert_type(:maybe_improper_list, [elem, tail], ctx),
    do: B.maybe_improper_list(convert(elem, ctx), convert(tail, ctx))

  defp convert_type(:nonempty_list, [t], ctx), do: B.nonempty_list(convert(t, ctx))

  defp convert_type(:nonempty_maybe_improper_list, [elem, tail], ctx),
    do: B.maybe_improper_list(convert(elem, ctx), convert(tail, ctx))

  defp convert_type(:tuple, types, ctx),
    do: B.fixed_tuple(Enum.map(types, &convert(&1, ctx)))

  defp convert_type(:map, [{:type, _, :map_field_assoc, [_, _]}], _), do: B.map()

  defp convert_type(:map, [{:type, _, :map_field_exact, [kt, vt]}], ctx),
    do: B.map(convert(kt, ctx), convert(vt, ctx))

  defp convert_type(:map, types, ctx) when is_list(types) do
    types
    |> Enum.map(fn
      {:type, _, :map_field_exact, [{:atom, _, key}, vtype]} -> {key, convert(vtype, ctx)}
      {:type, _, :map_field_assoc, _} -> nil
    end)
    |> Enum.filter(&Function.identity/1)
    |> B.fixed_map()
  end

  defp convert_type(:union, types, ctx), do: types |> Enum.map(&convert(&1, ctx)) |> B.one_of()
  defp convert_type(_, _, ctx), do: ctx.default
end
