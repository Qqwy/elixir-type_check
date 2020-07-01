defmodule TypeCheck.Builtin.Boolean do
  defstruct []

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_boolean(x) ->
            {:ok, []}
          _ ->
            {:error, {unquote(Macro.escape(s)), :not_a_boolean, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "boolean()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.boolean()
      end
    end
  end
end
