defmodule TypeCheck do
  defmacro __using__(_options) do
    quote do
      use TypeCheck.Macros
    end
  end
end
