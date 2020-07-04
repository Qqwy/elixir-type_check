defmodule TypeCheck.Builtin.Lazy do
  defstruct [:mfa]

  def lazily_expand_type(struct) do
    {module, function, arguments} = struct.mfa
    apply(module, function, arguments)
  end

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        type = TypeCheck.Builtin.Lazy.lazily_expand_type(unquote(Macro.escape(s)))
        check_code = TypeCheck.Protocols.ToCheck.to_check(type, unquote(param))
        {res, _} = Code.eval_quoted(check_code, [value: unquote(param)])
        res
      end
    end
  end
end
