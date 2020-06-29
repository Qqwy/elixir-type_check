defmodule TypeCheck.Builtin.Atom do
  defstruct []

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_atom(x) ->
            {:ok, []}
          _ ->
            {:error, {unquote(Macro.escape(s)), :not_an_atom, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.ToTypespec do
    def to_typespec(s) do
      quote do
        atom()
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "atom()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        StreamData.atom(:alphanumeric)
      end
    end
  end
end
