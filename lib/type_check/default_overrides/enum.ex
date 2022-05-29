defmodule TypeCheck.DefaultOverrides.Enum do
  alias TypeCheck.DefaultOverrides.Enumerable
  use TypeCheck

  @type! acc() :: any()

  @type! default() :: any()

  @type! element() :: any()

  @type! index() :: integer()

  @type! t() :: Enumerable.t()
end
