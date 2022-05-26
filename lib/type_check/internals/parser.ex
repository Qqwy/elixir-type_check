defmodule TypeCheck.Internals.Parser do
  @moduledoc """
  The parser for the default Elixir/Erlang `@spec`.

  Experimental!
  """

  alias TypeCheck.Builtin, as: B

  defmodule Context do
    @moduledoc """
    Container for context information of convert/2.
    """
    defstruct [:default, :vars]
    @type t :: %Context{default: TypeCheck.Type.t(), vars: %{String.t() => TypeCheck.Type.t()}}
  end

  @doc """
  Extract raw spec for the given MFA.

      iex> import TypeCheck.Internals.Parser
      iex> {:ok, _} = fetch_spec(Kernel, :node, 1)
  """
  @spec fetch_spec(module() | list(), atom(), arity()) :: {:error, String.t()} | {:ok, tuple()}
  def fetch_spec(module, function, arity) when is_atom(module) do
    case Code.Typespec.fetch_specs(module) do
      {:ok, specs} -> fetch_spec(specs, function, arity)
      :error -> {:error, "cannot fetch specs from the module"}
    end
  end

  def fetch_spec(specs, function, arity) when is_list(specs) do
    case specs |> Enum.find(fn {func, _spec} -> func == {function, arity} end) do
      {_, [spec]} -> {:ok, spec}
      {_, [_ | _]} -> {:error, "multiple specs for function"}
      {_, _spec} -> {:error, "unsupported spec"}
      nil -> {:error, "cannot find spec for function"}
    end
  end

  @doc """
  Fetch raw type definition for the given type with the given number of generic variables.
  """
  @spec fetch_type(module(), atom(), arity()) :: {:error, String.t()} | {:ok, any(), list()}
  def fetch_type(module, type, arity) do
    case fetch_types(module, type) do
      {:ok, []} -> {:error, "cannot find type with the given name"}
      {:ok, types} -> fetch_type(types, arity)
      {:error, err} -> {:error, err}
    end
  end

  @spec fetch_type(list(), arity()) :: {:error, String.t()} | {:ok, any(), list()}
  defp fetch_type(types, arity) when is_list(types) do
    case types |> Enum.find(fn {_, {_, _, vars}} -> length(vars) == arity end) do
      {_, {_, spec, vars}} -> {:ok, spec, vars}
      nil -> {:error, "cannot find type with the given arity"}
    end
  end

  @doc """
  Get list of all types from the module matching the given name.

  If no types found, empty list is returned.
  It is possible for list to contain multiple types if there are multiple type
  definitions with the same name but different amount of generic arguments.
  """
  @spec fetch_types(module() | list(), atom()) :: {:error, String.t()} | {:ok, list()}
  def fetch_types(module, type) when is_atom(module) do
    case Code.Typespec.fetch_types(module) do
      {:ok, types} -> fetch_types(types, type)
      :error -> {:error, "cannot fetch types from the module"}
    end
  end

  def fetch_types(types, type) when is_list(types) do
    filtered = types |> Enum.filter(fn {_, {name, _, _}} -> name == type end)
    {:ok, filtered}
  end

  @doc """
  Convert the raw spec extracted by `fetch_spec/3` into type_check type.

  The function is optimistic. If the type is not known, it assumes `any()`.

      iex> import TypeCheck.Builtin
      iex> import TypeCheck.Internals.Parser
      iex> {:ok, spec} = fetch_spec(Kernel, :is_atom, 1)
      iex> expected = function([term()], boolean())
      iex> ^expected = convert(spec)
  """
  # TODO(@orsinium):
  #  map(a, b)
  #  mfa
  #  keyword(t)
  #  identifier
  #  sized bitstring
  #  structs
  @spec convert(tuple()) :: TypeCheck.Type.t()
  def convert(type), do: convert(type, %Context{default: B.any(), vars: %{}})

  @spec convert(tuple(), Context.t()) :: TypeCheck.Type.t()

  defp convert({:type, _, name, vars}, ctx), do: convert_type(name, vars, ctx)
  defp convert({:atom, _, val}, _), do: B.literal(val)
  defp convert({:integer, _, val}, _), do: B.literal(val)
  defp convert({:ann_type, _, [_var, t]}, ctx), do: convert(t, ctx)

  defp convert({:remote_type, _, [{:atom, _, module}, {:atom, _, type}, vars]}, ctx) do
    case fetch_type(module, type, length(vars)) do
      {:ok, spec, _} -> convert(spec, ctx)
      {:error, _} -> ctx.default
    end
  end

  defp convert(_, ctx), do: ctx.default

  @spec convert_type(atom(), list() | atom(), Context.t()) :: TypeCheck.Type.t()
  # basic types
  defp convert_type(:any, [], _), do: B.any()
  defp convert_type(:atom, [], _), do: B.atom()
  defp convert_type(:binary, [], _), do: B.binary()
  defp convert_type(:bitstring, [], _), do: B.bitstring()
  defp convert_type(:boolean, [], _), do: B.boolean()
  defp convert_type(:pid, [], _), do: B.pid()
  defp convert_type(:no_return, [], _), do: B.none()
  defp convert_type(:none, [], _), do: B.none()

  # unsupported by type_check yet
  defp convert_type(:reference, [], ctx), do: ctx.default
  defp convert_type(:port, [], ctx), do: ctx.default

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
  defp convert_type(:module, [], _), do: B.module()
  defp convert_type(:nonempty_binary, [], _), do: B.nonempty_binary()
  defp convert_type(:nonempty_bitstring, [], _), do: B.nonempty_bitstring()
  defp convert_type(:byte, [], _), do: B.byte()
  defp convert_type(:char, [], _), do: B.char()
  defp convert_type(:node, [], _), do: B.atom()
  defp convert_type(:charlist, [], _), do: B.charlist()

  # shothands for generics
  defp convert_type(:fun, [], _), do: B.function()

  defp convert_type(:fun, [{:type, _, :any}, ret_type], ctx),
    do: B.function(convert(ret_type, ctx))

  defp convert_type(:list, [], _), do: B.list()
  defp convert_type(:map, :any, _), do: B.map()
  defp convert_type(:nonempty_list, [], _), do: B.nonempty_list()
  # improper lists are cursed, restrict it to regular lists
  defp convert_type(:nonempty_maybe_improper_list, [], _), do: B.nonempty_list()
  defp convert_type(:tuple, :any, _), do: B.tuple()

  # generics
  defp convert_type(:fun, [{:type, _, :product, arg_types}, ret_type], ctx),
    do: B.function(Enum.map(arg_types, &convert(&1, ctx)), convert(ret_type, ctx))

  defp convert_type(:bounded_fun, [t, _], ctx),
    # TODO(@orsinium): can we support constraints?
    do: convert(t, ctx)

  defp convert_type(:list, [t], ctx), do: B.list(convert(t, ctx))
  defp convert_type(:maybe_improper_list, [t, _tail], ctx), do: B.list(convert(t, ctx))
  defp convert_type(:nonempty_list, [t], ctx), do: B.nonempty_list(convert(t, ctx))

  defp convert_type(:nonempty_maybe_improper_list, [t, _tail], ctx),
    do: B.nonempty_list(convert(t, ctx))

  defp convert_type(:tuple, types, ctx),
    do: B.fixed_tuple(Enum.map(types, &convert(&1, ctx)))

  defp convert_type(:union, types, ctx), do: B.one_of(Enum.map(types, &convert(&1, ctx)))
  defp convert_type(_, _, ctx), do: ctx.default
end