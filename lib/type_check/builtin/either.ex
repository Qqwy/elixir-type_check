defmodule TypeCheck.Builtin.Either do
  defstruct [:left, :right]

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(x = %{left: left, right: right}, param) do
      left_check = TypeCheck.Protocols.ToCheck.to_check(left, param)
      right_check = TypeCheck.Protocols.ToCheck.to_check(right, param)
      quote do
        case unquote(left_check) do
          {:ok, bindings} -> {:ok, bindings}
          {:error, left_error} ->
            case unquote(right_check) do
              {:ok, bindings} -> {:ok, bindings}
              {:error, right_error} ->
                {:error, {unquote(Macro.escape(x)), :both_failed, %{left: left_error, right: right_error}, unquote(param)}}
            end
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.ToTypespec do
    def to_typespec(s) do
      quote do
        unquote(TypeCheck.Protocols.ToTypespec.to_typespec(s.left)) | unquote(TypeCheck.Protocols.ToTypespec.to_typespec(s.right))
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(either, opts) do
      TypeCheck.Protocols.Inspect.inspect(either.left, opts)
      |> Inspect.Algebra.glue("|")
      |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(either.right, opts))
      |> Inspect.Algebra.group
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        left_gen = TypeCheck.Protocols.ToStreamData.to_gen(s.left)
        right_gen = TypeCheck.Protocols.ToStreamData.to_gen(s.right)
        StreamData.one_of([left_gen, right_gen])
      end
    end
  end
end
