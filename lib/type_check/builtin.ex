defmodule TypeCheck.Builtin do
  def integer() do
    %TypeCheck.Builtin.Integer{}
  end

  def list(a) do
    %{type: :list, element_type: a}
  end
end
