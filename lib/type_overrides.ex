defmodule TypeOverrides do
  use TypeCheck
  import TypeCheck.Builtin
  @type! custom_enum() :: impl(Enumerable)
end

