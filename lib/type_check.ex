defmodule TypeCheck do
  defmacro __using__(_options) do
    quote do
      import TypeCheck.Macros

      Module.register_attribute(__MODULE__, TypeCheck.TypeDefs, accumulate: true, persist: true)
      @before_compile TypeCheck.Macros
    end
  end
end
