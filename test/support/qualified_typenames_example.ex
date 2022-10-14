defmodule QualifiedNamesExample do
  defstruct [:name]
  use TypeCheck, enable_runtime_checks: Mix.env() != :prod
  @type! t :: %__MODULE__{name: String.t()}

  @spec! example(%{optional(String.t()) => any} | QualifiedNamesExample.t()) ::
           QualifiedNamesExample.t()
  def example(%__MODULE__{} = struct), do: struct
end
