# Overrides Erlang's `:binary` module:
defmodule Elixir.TypeCheck.DefaultOverrides.Erlang.Binary do
  use TypeCheck
  @opaque! cp() :: {:am | :bm, reference()}

  @opaque! part() :: {start :: non_neg_integer(), length :: integer()}
end
