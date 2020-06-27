defmodule TypeCheck.Builtin.Integer do
  defstruct []

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_integer(x) ->
            :ok
          _ ->
          {:error, {unquote(Macro.escape(s)), :not_an_integer, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "integer()"
    end
  end
end
