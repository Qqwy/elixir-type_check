defmodule TypeCheck.Spec.Builtin do
  def integer() do
    %{type: :integer}
  end

  def binary() do
    %{type: :binary}
  end
end
