defmodule Example3 do
  def hello(x) do
    import TypeCheck
    conforms!(x, %{a: integer(), b: float()})
  end
end
