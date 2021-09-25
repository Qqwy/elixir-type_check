defmodule TypeCheck.DefaultOverrides.Enumerable do
  use TypeCheck
  @type! acc() :: {:cont, term()} | {:halt, term()} | {:suspend, term()}

  # TODO
  @type continuation() :: (acc() -> result())
  @autogen_typespec false
  @type! continuation() :: function()

  # TODO
  @type reducer() :: (element :: term(), current_acc :: acc() -> updated_acc :: acc())
  @autogen_typespec false
  @type! reducer() :: function()

  @type! result() ::
  {:done, term()}
  | {:halted, term()}
  | {:suspended, term(), continuation()}

  # TODO
  @type slicing_fun() :: (start :: non_neg_integer(), length :: pos_integer() -> [term()])
  @autogen_typespec false
  @type! slicing_fun() :: function()

  @type! t() :: impl(Elixir.Enumerable)
end
