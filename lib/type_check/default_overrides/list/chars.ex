defmodule TypeCheck.DefaultOverrides.List.Chars do
  use TypeCheck
  @type! t() :: impl(Elixir.List.Chars)
end
