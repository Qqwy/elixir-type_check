defmodule MapKeySyntaxExample do
  # Ensures this module is only compiled after TypeCheck's recompilation.
  # This is (only) necessary because this module is in the same project as TypeCheck's source itself.
  # Without this, using type overrides such as `String.t()` would not work.
  require TypeCheck.DefaultOverrides

  defstruct [:name]
  use TypeCheck
  @type! t :: %__MODULE__{name: String.t()}

  # binary() should be supported as map key
  # and be considered the same as `required(binary())`
  @spec! example(%{String.t() => any} | t()) :: t()
  def example(%__MODULE__{} = struct), do: struct
  def example(map), do: %__MODULE__{name: inspect(map)}
end
