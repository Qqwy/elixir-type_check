defmodule TypeCheck.Builtin.Range do
  defstruct [:range]

  use TypeCheck
  type t :: %__MODULE__{range: any()}

  type problem_tuple ::
         {t(), :not_an_integer, %{}, any()}
         | {t(), :not_in_range, %{}, integer()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s = %{range: range}, param) do
      quote location: :keep do
        case unquote(param) do
          x when not is_integer(x) ->
            {:error, {unquote(Macro.escape(s)), :not_an_integer, %{}, unquote(param)}}

          x when x not in unquote(Macro.escape(range)) ->
            {:error, {unquote(Macro.escape(s)), :not_in_range, %{}, unquote(param)}}

          _ ->
            {:ok, []}
        end
      end
    end

    def simple?(_) do
      false
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(struct, opts) do
      Inspect.Algebra.to_doc(struct.range, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        StreamData.integer(s.range)
      end
    end
  end
end
