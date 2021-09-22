# Required for the `@autogen_typespecs false` module doctests of TypeCheck.Macros
defmodule AutogenTypespecsExample do
  use TypeCheck

  # The typespec of `foo` is auto-generated:
  # A line `@type foo() :: integer()` will be visible in the documentation/Dialyzer.
  @type! foo() :: integer()

  # The typespec of `bar` is _not_ auto-generated.
  # As such, we could write a completely different `@type` (or leave it out all-together).
  @autogen_typespec false
  @type! bar() :: integer()
end
