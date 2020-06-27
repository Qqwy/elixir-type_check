defmodule TypeCheck do
  defmacro __using__(_options) do
    quote do
      use TypeCheck.Macros
    end
  end

  defmacro conforms(value, type) do
    type = eval_type(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      case unquote(check) do
        :ok -> {:ok, unquote(value)}
        other -> other
      end
    end
  end

  defmacro conforms?(value, type) do
    type = eval_type(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      unquote(check) == :ok
    end
  end

  defmacro conforms!(value, type) do
    type = eval_type(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      case unquote(check) do
        :ok -> unquote(value)
        {:error, other} -> raise TypeCheck.TypeError, other
      end
    end
  end

  defp eval_type(type_ast, caller) do
    type_ast = TypeCheck.Internals.PreExpander.rewrite(type_ast, caller)
    {type, []} = Code.eval_quoted(quote do import TypeCheck.Builtin; unquote(type_ast) end, [], caller)
    type
  end
end
