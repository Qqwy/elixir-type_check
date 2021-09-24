defmodule DebugExample do
  @compile :inline
  @compile {:inline_size, 100}

  use TypeCheck, debug: false

  @type! myparam :: integer()

  @spec! stringify(myparam(), boolean()) :: binary()
  def stringify(val, _bool) do
    # if val > 10 do
    #   val
    # else
      to_string(val)
    # end
  end

  @spec! average(list(number())) :: {:ok, number()} | {:error, :empty}
  def average([]), do: {:error, :empty}
  # def average(vals) when length(vals) < 3 do
  def average(vals) do
    res = Enum.sum(vals) / Enum.count(vals)
    {:ok, res}
  end
end
