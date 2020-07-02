defmodule TypeCheck.Builtin.Lazy do
  defstruct [:type_ast, :caller]

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      IO.inspect(s)

      snippet =
        quote location: :keep do
        IO.inspect(unquote(Macro.escape(s.caller)), label: :inner)
        import unquote(Module.concat(s.caller.module, TypeCheck))
        check =
          unquote(Macro.escape(s.type_ast))
          |> TypeCheck.Type.build_unescaped(unquote(Macro.escape(s.caller)))
          |> TypeCheck.Protocols.ToCheck.to_check(Macro.var(:value, nil))

        IO.inspect(unquote(Macro.escape(s.caller)), label: :outer)
        {res, _} = Code.eval_quoted(check, [value: unquote(param)], unquote(Macro.escape(s.caller)))
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
