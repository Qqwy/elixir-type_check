defmodule Example3 do
  import TypeCheck.Builtin
  def hello(x) do
    import TypeCheck
    conforms!(x, %{a: integer(), b: float()})
  end
end
