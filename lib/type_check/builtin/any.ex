defmodule TypeCheck.Builtin.Any do
  defstruct []

  use TypeCheck
  type problem_tuple :: none()

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(_, _param) do
      quote do
        :ok
      end
    end

    def simple?(_) do
      true
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "any()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.term()
      end
    end
  end
end
