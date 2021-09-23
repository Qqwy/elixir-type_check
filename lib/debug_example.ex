defmodule DebugExample do
  @compile :inline
  @compile {:inline_size, 100}

  use TypeCheck, debug: true

  @type! myparam :: integer()

  @spec! stringify(myparam) :: binary()
  def stringify(val) do
    to_string(val)
  end
end
