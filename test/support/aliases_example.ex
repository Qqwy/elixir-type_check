defmodule AliasesExample.Example do
  # Ensures this module is only compiled after TypeCheck's recompilation.
  # This is (only) necessary because this module is in the same project as TypeCheck's source itself.
  # Without this, using type overrides such as `String.t()` would not work.
  require TypeCheck.DefaultOverrides

  alias AliasesExample.Example
  defstruct [:name]
  use TypeCheck, enable_runtime_checks: Mix.env() != :prod
  @type! t :: %__MODULE__{name: String.t()}

  @spec! hydrate(Example.t()) :: Example.t()
  def hydrate(struct), do: struct
end
