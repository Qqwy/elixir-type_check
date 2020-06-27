defmodule TypeCheck do
  defmacro __using__(_options) do
    quote do
      use TypeCheck.Macros
    end
  end

  defmacro conforms(value, type) do
    check = TypeCheck.Protocols.ToCheck.to_check(type, Macro.var(:value, __MODULE__))
    quote do
      case unquote(check) do
        :ok -> {:ok, value}
        other -> other
      end
    end
  end

  defmacro conform?(value, type) do
    check = TypeCheck.Protocols.ToCheck.to_check(type, Macro.var(:value, __MODULE__))
    quote do
      unquote(check) == :ok
    end
  end

  defmacro conform!(value, type) do
    check = TypeCheck.Protocols.ToCheck.to_check(type, Macro.var(:value, __MODULE__))
    quote do
      case unquote(check) do
        :ok -> value
        other -> raise ArgumentError, inspect(other)
      end
    end
  end
end
