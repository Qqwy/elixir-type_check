defmodule MapKeySyntaxExample do
  defstruct [:name]
  use TypeCheck
  @type! t :: %__MODULE__{name: String.t()}

  # String.t() should be supported as map key
  # and be considered the same as `required(String.t())`
  @spec! example(%{String.t() => any} | t()) :: t()
  def example(%__MODULE__{} = struct), do: struct
end
