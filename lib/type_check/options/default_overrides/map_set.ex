defmodule TypeCheck.Options.DefaultOverrides.MapSet do
  use TypeCheck
  @type! t() :: t(term())

  @opaque! t(value) :: %Elixir.MapSet{map: map(value, literal([]))}

  @type! value() :: term()
end
