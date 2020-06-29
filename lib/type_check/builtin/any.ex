defmodule TypeCheck.Builtin.Any do
  defstruct []

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(_, _param) do
      quote do
        {:ok, []}
      end
    end
  end

  defimpl TypeCheck.Protocols.ToTypespec do
    def to_typespec(s) do
      quote do
        any()
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "any()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        StreamData.term()
      end
    end
  end
end
