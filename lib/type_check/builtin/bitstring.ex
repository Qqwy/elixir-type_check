defmodule TypeCheck.Builtin.Bitstring do
  defstruct []

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_bitstring(x) ->
            {:ok, []}
          _ ->
            {:error, {unquote(Macro.escape(s)), :not_a_bitstring, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "bitstring()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        StreamData.bitstring()
      end
    end
  end
end
