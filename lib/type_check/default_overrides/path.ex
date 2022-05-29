defmodule TypeCheck.DefaultOverrides.Path do
  use TypeCheck

  alias TypeCheck.DefaultOverrides.IO

  @type! t() :: IO.chardata()
end
