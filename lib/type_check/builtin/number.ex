defmodule TypeCheck.Builtin.Number do
  defstruct []

  use TypeCheck
  type problem_tuple :: {%__MODULE__{}, :no_match, %{}, val :: any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_number(x) ->
            {:ok, []}
          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "number()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.one_of([StreamData.integer(), StreamData.float()])
      end
    end
  end
end
