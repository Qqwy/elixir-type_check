defmodule RewriteArgs do
  # Ensures this module is only compiled after TypeCheck's recompilation.
  # This is (only) necessary because this module is in the same project as TypeCheck's source itself.
  # Without this, using type overrides such as `String.t()` would not work.
  require TypeCheck.DefaultOverrides

  defstruct [:name]
  use TypeCheck, enable_runtime_checks: Mix.env() != :prod
  @type! t :: ModelWithTypeArgs.t(:foo | :bar, :foo2 | :bar2)

  @type! local(a, b) :: %{a: a, b: b}

  @spec! hydrate(local(:foo | :bar, :foo2 | :bar2)) :: t()
  def hydrate(input), do: input

  @spec! hydrate2(t()) :: local(:foo | :bar, :foo2 | :bar2)
  def hydrate2(input), do: input
end
