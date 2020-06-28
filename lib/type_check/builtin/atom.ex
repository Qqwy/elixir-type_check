defmodule TypeCheck.Builtin.Atom do
  defstruct []

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(x, param) do
      quote do
        case unquote(param) do
          x when is_atom(x) ->
            {:ok, []}
          _ ->
            {:error, {unquote(x), :not_an_atom, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "atom()"
    end
  end
end
