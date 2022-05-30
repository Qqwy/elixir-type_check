defmodule TypeCheck.DefaultOverrides.String.Chars do
  use TypeCheck
  @type! t() :: impl(Elixir.String.Chars)
end
