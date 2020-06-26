defmodule TypeCheck.Builtin do
  def integer() do
    %TypeCheck.Builtin.Integer{}
  end

  def list(a) do
    %TypeCheck.Builtin.List{element_type: a}
  end
end
