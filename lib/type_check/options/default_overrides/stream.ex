defmodule TypeCheck.Options.DefaultOverrides.Stream do
  use TypeCheck
  @type! acc() :: any()

  @type! default() :: any()

  @type! element() :: any()

  @type! index() :: non_neg_integer()

  @type! timer() :: non_neg_integer() | :infinity
end
