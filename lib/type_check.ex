defmodule TypeCheck do
  defmacro __using__(_options) do
    quote do
      # require TypeCheck.Spec
      import TypeCheck.Spec, only: [type: 1, typep: 1, opaque: 1, spec: 1]
      Module.register_attribute(__MODULE__, TypeCheck.Spec.Raw, persist: true, accumulate: true, persist: true)
      @before_compile TypeCheck.Spec
    end
  end
end
