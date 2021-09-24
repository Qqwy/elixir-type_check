# Overrides Erlang's `:binary` module:
defmodule Elixir.TypeCheck.Options.DefaultOverrides.Erlang.Binary do
  use TypeCheck
  # TODO
  @opaque cp() :: {any(), reference()}
  @autogen_typespec false
  @opaque! cp() :: {'am' | 'bm', term()}

  @opaque! part() :: {start :: non_neg_integer(), length :: integer()}
end
