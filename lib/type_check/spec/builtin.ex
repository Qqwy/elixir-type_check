defmodule TypeCheck.Spec.Builtin do
  def integer() do
    %{type: :integer}
  end

  def float() do
    %{type: :float}
  end

  def binary() do
    %{type: :binary}
  end

  def a | b do
    %{type: :or, lhs: a, rhs: b}
  end

  #  `->` needs to be handled separately
  # def function(args, result) do
  #   %{type: :function, args: args, result: result}
  # end
end
