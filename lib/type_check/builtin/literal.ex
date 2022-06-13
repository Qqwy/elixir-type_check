defmodule TypeCheck.Builtin.Literal do
  defstruct [:value]

  use TypeCheck
  @type! t :: %__MODULE__{value: term()}
  @type! problem_tuple :: {:not_same_value, %{}, value :: term()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s = %{value: value}, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when x === unquote(Macro.escape(value)) ->
            {:ok, [], x}

          _ ->
            {:error, {:not_same_value, %{}, unquote(param)}}
        end
      end
    end
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
