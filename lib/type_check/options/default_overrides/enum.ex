defmodule TypeCheck.Options.DefaultOverrides.Enum do
  alias TypeCheck.Options.DefaultOverrides.Enumerable
  use TypeCheck
  @type! acc() :: any()
  @type! default() :: any()
  @type! element() :: any()
  @type! index() :: integer()
  @type! t() :: Enumerable.t()
end
