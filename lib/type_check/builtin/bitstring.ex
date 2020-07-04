defmodule TypeCheck.Builtin.Bitstring do
  defstruct []

  use TypeCheck
  type problem_tuple_type :: {:error, %__MODULE__{}, :no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_bitstring(x) ->
            {:ok, []}
          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
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
      def to_gen(_s) do
        StreamData.bitstring()
      end
    end
  end
end
