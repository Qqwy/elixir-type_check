defmodule TypeCheck.DefaultOverrides.Keyword do
  use TypeCheck
  @type! key() :: atom()

  @type! t() :: [{key(), value()}]

  @type! t(value) :: [{key(), value}]

  @type! value() :: any()
end
