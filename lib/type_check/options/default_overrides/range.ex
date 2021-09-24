defmodule TypeCheck.Options.DefaultOverrides.Range do
  use TypeCheck
  @type! limit() :: integer()

  @type! step() :: pos_integer() | neg_integer()

  @type! t() :: %Elixir.Range{first: limit(), last: limit(), step: step()}

  @type! t(first, last) :: %Elixir.Range{first: first, last: last, step: step()}
end
