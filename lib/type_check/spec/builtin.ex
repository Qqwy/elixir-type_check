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

  def map() do
    %{type: :map}
  end

  def pid() do
    %{type: :pid}
  end

  def port() do
    %{type: :port}
  end

  def reference() do
    %{type: :reference}
  end

  def struct() do
    %{type: :struct}
  end

  def tuple() do
    %{type: :tuple}
  end

  def neg_integer() do
    %{type: :neg_integer}
  end

  def pos_integer() do
    %{type: :pos_integer}
  end

  def non_neg_integer() do
    %{type: :non_neg_integer}
  end

  def list(element_type) do
    %{type: :list, element_type: element_type}
  end

  def nonempty_list(element_type) do
    %{type: :nonempty_list, element_type: element_type}
  end

  def literal(value) do
    %{type: :literal, value: value}
  end

  def a .. b do
    %{type: :range, lower: a, higher: b}
  end

  def a | b do
    %{type: :or, lhs: a, rhs: b}
  end

  #  `->` needs to be handled separately
  # def function(args, result) do
  #   %{type: :function, args: args, result: result}
  # end
end
