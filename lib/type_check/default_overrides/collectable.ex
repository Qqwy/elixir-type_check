defmodule TypeCheck.DefaultOverrides.Collectable do
  use TypeCheck
  @type! command() :: {:cont, term()} | :done | :halt
  @type! t() :: impl(Elixir.Collectable)
end
