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
        TypeCheck.apply!(unquote(type), unquote(module), unquote(function), unquote(args))
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
      #TypeCheck.Type< %Range{first: integer(), last: integer(), step: any()} >

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
        ctx = %{Parser.Context.default() | vars: vars}
        {:ok, Parser.convert(type, ctx)}

      {:error, err} ->
        {:error, err}
    end
  end
end
