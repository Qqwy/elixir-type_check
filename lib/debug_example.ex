defmodule DebugExample do
  @compile :inline
  @compile {:inline_size, 100}

  use TypeCheck, debug: true

  @type! myparam :: integer()

  @spec! stringify(myparam, boolean()) :: binary()
  def stringify(val, _bool) do
    if val > 10 do
      val
    else
      to_string(val)
    end
  end

  @spec! average(list(number())) :: number()
  def average(vals) do
    Enum.sum(vals) / Enum.count(vals)
  end
end
