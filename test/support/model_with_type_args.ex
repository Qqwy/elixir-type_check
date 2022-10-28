defmodule ModelWithTypeArgs do
  use TypeCheck, enable_runtime_checks: Mix.env() != :prod

  @type! t(a, b) :: %{a: a, b: b}
end
