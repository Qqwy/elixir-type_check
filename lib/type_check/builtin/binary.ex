defmodule TypeCheck.Builtin.Binary do
  defstruct []

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_binary(x) ->
            {:ok, []}
          _ ->
            {:error, {unquote(Macro.escape(s)), :not_a_binary, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "binary()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        StreamData.binary()
      end
    end
  end
end
