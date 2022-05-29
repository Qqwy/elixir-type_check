defmodule TypeCheck.DefaultOverrides.Code do
  use TypeCheck

  @type! binding() :: [{atom() | tuple(), any()}]
end
