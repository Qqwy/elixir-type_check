defmodule TypeCheck do
  require TypeCheck.Type

  defmacro __using__(_options) do
    quote do
      use TypeCheck.Macros
      import TypeCheck.Builtin
    end
  end

  defmacro conforms(value, type) do
    type = TypeCheck.Type.build_unescaped(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      case unquote(check) do
        {:ok, bindings} -> {:ok, unquote(value)}
        {:error, problem} -> {:error, TypeCheck.TypeError.exception(problem)}
      end
    end
  end

  defmacro conforms?(value, type) do
    type = TypeCheck.Type.build_unescaped(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      match?({:ok, _}, unquote(check))
    end
  end

  defmacro conforms!(value, type) do
    type = TypeCheck.Type.build_unescaped(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      case unquote(check) do
        {:ok, _bindings} -> unquote(value)
        {:error, other} -> raise TypeCheck.TypeError, other
      end
    end
  end

  def dynamic_conforms(value, type) do
    check_code = TypeCheck.Protocols.ToCheck.to_check(type, Macro.var(:value, nil))
    case Code.eval_quoted(check_code, [value: value]) do
      {{:ok, _}, _} -> {:ok, value}
      {{:error, problem}, _} -> {:error, TypeCheck.TypeError.exception(problem)}
    end
  end

  def dynamic_conforms?(value, type) do
    case dynamic_conforms(value, type) do
      {:ok, _value} -> true
      _other -> false
    end
  end

  def dynamic_conforms!(value, type) do
    case dynamic_conforms(value, type) do
      {:ok, value} -> value
      {:error, exception} -> raise exception
    end
  end
end
