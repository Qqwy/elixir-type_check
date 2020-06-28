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
        :ok -> {:ok, unquote(value)}
        other -> other
      end
    end
  end

  defmacro conforms?(value, type) do
    type = TypeCheck.Type.build_unescaped(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      unquote(check) == :ok
    end
  end

  defmacro conforms!(value, type) do
    type = TypeCheck.Type.build_unescaped(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      case unquote(check) do
        :ok -> unquote(value)
        {:error, other} -> raise TypeCheck.TypeError, other
      end
    end
  end
end
