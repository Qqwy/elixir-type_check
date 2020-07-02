defmodule TypeCheck.Builtin.Lazy do
  defstruct [:type_ast, :caller]

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do

      snippet =
        quote location: :keep do
          TypeCheck.Type.build_unescaped(unquote(Macro.escape(s.type_ast)), __ENV__)
          |> TypeCheck.Protocols.ToCheck.to_check(Macro.var(:value, nil))
        end

      quote do
        {res, _} = Code.eval_quoted(unquote(snippet), [value: unquote(param)])
        IO.inspect(res, label: :res)
        res
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, _opts) do
      "lazy(#{Macro.to_string(s.type_ast)})"
    end
  end
end
