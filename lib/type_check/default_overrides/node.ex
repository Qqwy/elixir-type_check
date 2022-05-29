defmodule TypeCheck.DefaultOverrides.Node do
  use TypeCheck

  @type! state() :: :visible | :hidden | :connected | :this | :known

  @type! t() :: node()
end
