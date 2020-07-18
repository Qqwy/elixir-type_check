defmodule Addition do
  @compile {:inline, ["add (overridable 1)": 2]}
  use TypeCheck
  spec add(number(), number()) :: number()
  def add(a, b) do
    a + b
  end

  def baseline_add(a, b) do
    a + b
  end
end

