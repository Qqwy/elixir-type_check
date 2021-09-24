defmodule TypeCheck.Options.DefaultOverrides.File.Stream do
  use TypeCheck
  @type! t() :: %File.Stream{
    line_or_bytes: term(),
    modes: term(),
    path: term(),
    raw: term()
  }
end
