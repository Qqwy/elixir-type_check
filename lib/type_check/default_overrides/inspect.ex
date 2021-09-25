defmodule TypeCheck.DefaultOverrides.Inspect do
  use TypeCheck
  @type! t() :: impl(Elixir.Inspect)
end
