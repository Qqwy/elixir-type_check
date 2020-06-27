defmodule TypeCheck.Builtin.Range do
  defstruct [:range]


  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(%{range: range}, param) do
      quote location: :keep do
        case unquote(param) do
          x when not is_integer(x) ->
            {:error, {TypeCheck.Builtin.Range, :not_an_integer, %{}, unquote(param)}}
          x when x not in unquote(Macro.escape(range)) ->
            {:error, {TypeCheck.Builtin.Range, :not_in_range, %{range: unquote(Macro.escape(range))}, unquote(param)}}
          _ ->
            :ok
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(struct, opts) do
      Inspect.Algebra.to_doc(struct.range, opts)
    end
  end
end
