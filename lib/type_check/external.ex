defmodule TypeCheck.External do
  @moduledoc """
  Working with regular Elixir and Erlang `@spec` and `@type` definitions.

  ## Experimental

  This module is experimental. Use it at your own risk only in a test-covered code.
  If it explodes, please, [open an issue](https://github.com/Qqwy/elixir-type_check/issues).

  """
  alias TypeCheck.Internals.Parser

  @doc """
  Ensure at runtime that arguments at result of function call conform the function spec.

  The function spec is extracted at compile time from the regular Elixir (or Erlang) `@spec`.

  ## Examples

      iex> import TypeCheck.External
      iex> enforce_spec!(Kernel.abs(-13))
      13
      iex> enforce_spec!(Kernel.abs("hi"))
      ** (TypeCheck.TypeError) At lib/type_check.ex:279:
          `"hi"` is not a number.
  """
  @spec enforce_spec!(Macro.t()) :: Macro.t() | no_return
  defmacro enforce_spec!(expr) do
    with {module, function, args} <- Parser.ast_to_mfa(expr),
         {:ok, spec} <- Parser.fetch_spec(module, function, length(args)) do
      type = spec |> Parser.convert() |> Macro.escape()

      quote do
        TypeCheck.External.apply!(
          unquote(type),
          unquote(module),
          unquote(function),
          unquote(args)
        )
      end
    else
      {:error, err} -> raise TypeCheck.CompileError, err
    end
  end

  @doc """
  Extract TypeCheck type from the regular Elixir (or Erlang) `@spec` of the given function.

  ## Examples

      iex> import TypeCheck.External
      iex> {:ok, type} = fetch_spec(Kernel, :abs, 1)
      iex> type
      #TypeCheck.Type< (number() -> number()) >
      iex> {:ok, type} = fetch_spec(Atom, :to_string, 1)
      iex> type
      #TypeCheck.Type< (atom() -> binary()) >
      iex> fetch_spec(Kernel, :non_existent, 1)
      {:error, "cannot find spec for function"}
  """
  @spec fetch_spec(module(), atom(), arity()) :: TypeCheck.Type.t()
  def fetch_spec(module, function, arity) do
    case Parser.fetch_spec(module, function, arity) do
      {:ok, spec} -> {:ok, Parser.convert(spec)}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Extract TypeCheck type from the regular Elixir (or Erlang) `@type` with the given name.

  To fetch a generic type, you must pass a list of types to be placed instead of
  generic variables. If you don't know these types, just punch in `any()`
  as many times as you need. For example, to fetch the type of `Range.t(left, right)`,
  you need to pass `[number(), number()]` or `[any(), any()]`.

  ## Examples

  Fetching a regular type:

      iex> import TypeCheck.External
      iex> {:ok, type} = fetch_type(String, :t)
      iex> type
      #TypeCheck.Type< binary() >

  Fetching a generic type:

      iex> import TypeCheck.External
      iex> import TypeCheck.Builtin
      iex> {:ok, type} = fetch_type(:elixir, :keyword, [number()])
      iex> type
      #TypeCheck.Type< list({atom(), number()}) >
      iex> {:ok, type} = fetch_type(Range, :t, [integer(), integer()])
      iex> type
      #TypeCheck.Type< %Range{first: integer(), last: integer(), step: pos_integer() | neg_integer()} >

  Fetching non-existent type causes an error:

      iex> import TypeCheck.External
      iex> fetch_type(String, :non_existent)
      {:error, "cannot find type with the given name"}
  """
  @spec fetch_type(module(), atom(), [TypeCheck.Type.t()]) :: TypeCheck.Type.t()
  def fetch_type(module, type, var_types \\ []) do
    arity = length(var_types)

    case Parser.fetch_type(module, type, arity) do
      {:ok, type, var_names} ->
        vars = Enum.zip(var_names, var_types) |> Map.new()
        ctx = %{Parser.Context.default() | vars: vars, module: module}
        {:ok, Parser.convert(type, ctx)}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  The same as `Kernel.apply/3` but ensures that values conform the given type.

  The first argument must be a function type of the function to be called.

  In case of type error, raises an exception.

  ## Examples

      iex> alias TypeCheck.Builtin, as: B
      iex> type = B.function([B.number], B.number)
      iex> TypeCheck.External.apply!(type, Kernel, :abs, [-13])
      13
      iex> TypeCheck.External.apply!(type, Kernel, :abs, ["hello"])
      ** (TypeCheck.TypeError) At lib/type_check.ex:279:
          `"hello"` is not a number.

  """
  @spec apply!(TypeCheck.Type.t(), module(), atom(), list()) :: any()
  def apply!(type, module, function, args) do
    case apply(type, module, function, args) do
      {:ok, result} -> result
      {:error, exception} -> raise exception
    end
  end

  @doc """
  The same as `TypeCheck.External.apply/3` but ensures that values conform the given type.

  Returns `{:error, reason}` on failure, `{:ok, function_call_result}` otherwise.

      iex> alias TypeCheck.Builtin, as: B
      iex> type = B.function([B.number], B.number)
      iex> TypeCheck.External.apply(type, Kernel, :abs, [-13])
      {:ok, 13}
      iex> {:error, err} = TypeCheck.External.apply(type, Kernel, :abs, [false])
      iex> err.message
      "At lib/type_check.ex:279:\\n    `false` is not a number."

  """
  @spec apply(TypeCheck.Type.t(), module(), atom(), list()) ::
          {:ok, any()} | {:error, TypeCheck.TypeError.t()}
  def apply(type, module, function, args) do
    {ptypes, rtype} = split_func_type(type)

    with :ok <- check_params(args, ptypes),
         result <- Kernel.apply(module, function, args),
         {:ok, _} <- TypeCheck.dynamic_conforms(result, rtype) do
      {:ok, result}
    end
  end

  @spec check_params(list(), [TypeCheck.Type.t()]) :: :ok | {:error, TypeCheck.TypeError.t()}
  defp check_params([value | values], [type | types]) do
    case TypeCheck.dynamic_conforms(value, type) do
      {:ok, _} -> check_params(values, types)
      {:error, reason} -> {:error, reason}
    end
  end

  defp check_params(_, _), do: :ok

  @spec split_func_type(TypeCheck.Type.t()) :: {[TypeCheck.Type.t()], TypeCheck.Type.t()}
  defp split_func_type(%{param_types: ptypes, return_type: rtype}), do: {ptypes, rtype}

  defp split_func_type(%{__struct__: TypeCheck.Builtin.OneOf, choices: types}) do
    ptypes =
      types
      |> Enum.map(fn %{param_types: params} -> params end)
      |> List.zip()
      |> Enum.map(fn types -> types |> Tuple.to_list() |> TypeCheck.Builtin.one_of() end)

    rtypes = Enum.map(types, fn %{return_type: rtype} -> rtype end)
    {TypeCheck.Builtin.one_of(ptypes), TypeCheck.Builtin.one_of(rtypes)}
  end
end
