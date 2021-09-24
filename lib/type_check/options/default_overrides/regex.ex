defmodule TypeCheck.Options.DefaultOverrides.Regex do
  use TypeCheck
  @type! t() :: %Elixir.Regex{
    opts: binary(),
    re_pattern: term(),
    re_version: term(),
    source: binary()
  }
end
