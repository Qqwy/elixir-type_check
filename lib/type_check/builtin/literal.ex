defmodule TypeCheck.Builtin.Literal do
  defstruct [:value]

  use TypeCheck
  @type! t :: %__MODULE__{value: term()}
  @type! problem_tuple :: {t(), :not_same_value, %{}, value :: term()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s = %{value: value}, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when x === unquote(Macro.escape(value)) ->
            {:ok, [], x}

          _ ->
            {:error, {unquote(Macro.escape(s)), :not_same_value, %{}, unquote(param)}}
        end
      end
    end

    def needs_slow_check?(_), do: false
    def to_check_slow(t, param), do: to_check(t, param)
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(literal, opts) do
      case literal.value do
        %Range{} ->
          "literal("
          |> Inspect.Algebra.glue(Inspect.Algebra.to_doc(literal.value, opts))
          |> Inspect.Algebra.glue(")")

        _ ->
          Inspect.Algebra.to_doc(literal.value, opts)
      end
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        StreamData.constant(s.value)
      end
    end
  end
end
