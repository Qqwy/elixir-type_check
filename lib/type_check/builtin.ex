defmodule TypeCheck.Builtin do
  def any() do
    %TypeCheck.Builtin.Any{}
  end

  def atom() do
    %TypeCheck.Builtin.Atom{}
  end

  def integer() do
    %TypeCheck.Builtin.Integer{}
  end

  def float() do
    %TypeCheck.Builtin.Float{}
  end

  def list() do
    list(any())
  end

  def list(a) do
    %TypeCheck.Builtin.List{element_type: a}
  end

  def tuple(element_types_list) when is_list(element_types_list) do
    %TypeCheck.Builtin.Tuple{element_types: element_types_list}
  end

  def tuple(size) when is_integer(size) do
    elems =
      0..size
      |> Enum.map(fn -> any() end)
    tuple(elems)
  end

  def literal(value) do
    %TypeCheck.Builtin.Literal{value: value}
  end

  def either(left, right) do
    %TypeCheck.Builtin.Either{left: left, right: right}
  end

  def left | right do
    either(left, right)
  end

  def range(range = lower..higher) do
    %TypeCheck.Builtin.Range{range: range}
  end

  def range(lower, higher) do
    %TypeCheck.Builtin.Range{range: lower..higher}
  end

  def type() do
    any()
  end
end