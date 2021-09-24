defmodule TypeCheck.Options.DefaultOverrides.Inspect do
  use TypeCheck
  @type! t() :: impl(Elixir.Inspect)
end
