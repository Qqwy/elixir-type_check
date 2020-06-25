defmodule TypeCheck.Builtin do
  def integer() do
    %{type: :integer}
  end

  def list(a) do
    %{type: :list, element_type: a}
  end
end
