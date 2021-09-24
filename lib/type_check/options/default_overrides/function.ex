defmodule TypeCheck.Options.DefaultOverrides.Function do
  use TypeCheck
  @type! information() ::
  :arity
  | :env
  | :index
  | :module
  | :name
  | :new_index
  | :new_uniq
  | :pid
  | :type
  | :uniq
end
