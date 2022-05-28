defmodule TypeCheck.DefaultOverrides.Enumerable do
  use TypeCheck
  @type! acc() :: {:cont, term()} | {:halt, term()} | {:suspend, term()}

  @type! continuation() :: (acc() -> result())

  @type! reducer() :: (element :: term(), current_acc :: acc() -> updated_acc :: acc())

  @type! result() ::
  {:done, term()}
  | {:halted, term()}
  | {:suspended, term(), continuation()}

  @type! slicing_fun() :: (start :: non_neg_integer(), length :: pos_integer() -> [term()])

  @type! t() :: impl(Elixir.Enumerable)
end
