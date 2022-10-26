defmodule MapWithMultipleOptionals do
  # Ensures this module is only compiled after TypeCheck's recompilation.
  require TypeCheck.DefaultOverrides

  use TypeCheck

  @type! t :: %{:foo => integer(), optional(:bar) => float(), optional(:baz) => String.t()}

  # binary() should be supported as map key
  # and be considered the same as `required(binary())`
  @spec! example(t()) :: t()
  def example(map), do: map
end
