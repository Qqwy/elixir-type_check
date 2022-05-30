defmodule TypeCheck.DefaultOverrides.OptionParser do
  use TypeCheck

  alias TypeCheck.DefaultOverrides.String

  @type! argv() :: list(String.t())

  @type! errors() :: list({String.t(), String.t() | nil})

  @type! options() :: list({:switches, keyword()} | {:strict, keyword()} | {:aliases, keyword()})

  @type! parsed() :: keyword()
end
