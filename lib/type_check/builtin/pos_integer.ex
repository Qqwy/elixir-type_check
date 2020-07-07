defmodule TypeCheck.Builtin.PosInteger do
  defstruct []

  use TypeCheck
  type t :: %__MODULE__{}
  type problem_tuple :: {t(), :no_match, map(), any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_integer(x) and x > 0 ->
            {:ok, []}

          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "positive_integer()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.positive_integer()
      end
    end
  end
end
