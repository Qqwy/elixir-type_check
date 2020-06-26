defmodule TypeCheck.Builtin.Any do
  defstruct []

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(_, _param) do
      quote do
        :ok
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "any()"
    end
  end
end
