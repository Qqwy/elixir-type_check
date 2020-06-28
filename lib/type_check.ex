defmodule TypeCheck do
  require TypeCheck.Type

  defmacro __using__(_options) do
    quote do
      use TypeCheck.Macros
    end
  end

  defmacro conforms(value, type) do
    type = TypeCheck.Type.build_unescaped(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      case unquote(check) do
        {:ok, bindings} -> {:ok, unquote(value)}
        other -> other
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
      {other, _} -> other
    end
  end

  def dynamic_conforms?(value, type) do
    case dynamic_conforms(value, type) do
      {:ok, value} -> true
      other -> false
    end
  end

  def dynamic_conforms!(value, type) do
    case dynamic_conforms(value, type) do
      {:ok, value} -> value
      {:error, other} -> raise TypeCheck.TypeError, other
    end
  end
end
