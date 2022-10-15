defmodule MapKeySyntaxExample do
  defstruct [:name]
  use TypeCheck
  @type! t :: %__MODULE__{name: binary()}

  # binary() should be supported as map key
  # and be considered the same as `required(binary())`
  @spec! example(%{binary() => any} | t()) :: t()
  def example(%__MODULE__{} = struct), do: struct
end
