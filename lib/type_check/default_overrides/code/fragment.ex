defmodule TypeCheck.DefaultOverrides.Code.Fragment do
  use TypeCheck

  @type! binding() :: [{atom() | tuple(), any()}]
end
