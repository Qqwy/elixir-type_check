defmodule TypeCheck.Builtin.Integer do
  defstruct []

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(_integer, param) do
      quote do
        if is_integer(unquote(param)) do
          :ok
        else
          {:error, TypeCheck.Builtin.Integer}
        end
      end
    end
  end
end
