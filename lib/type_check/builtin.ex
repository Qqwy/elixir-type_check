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

  # prevents double-expanding
  # when called as `tuple([1,2,3])` by the user.
  def tuple(list = %TypeCheck.Builtin.FixedList{}) do
    tuple(list.element_types)
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

  def map() do
    %TypeCheck.Builtin.Map{key_type: any(), value_type: any()}
  end

  def map(key_type, value_type) do
    %TypeCheck.Builtin.Map{key_type: key_type, value_type: value_type}
  end

  def fixed_map(keywords)

  # prevents double-expanding
  # when called as `fixed_map(%{a: 1, b: 2})` by the user.
  def fixed_map(map = %TypeCheck.Builtin.FixedMap{}) do
    map
  end

  def fixed_map(keywords) when is_map(keywords) or is_list(keywords) do
    %TypeCheck.Builtin.FixedMap{keypairs: Enum.into(keywords, [])}
  end


  def fixed_list(element_types)

  # prevents double-expanding
  # when called as `fixed_list([1,2,3])` by the user.
  def fixed_list(list = %TypeCheck.Builtin.FixedList{}) do
    list
  end

  def fixed_list(element_types) when is_list(element_types) do
    %TypeCheck.Builtin.FixedList{element_types: element_types}
  end

  def named_type(name, type) do
    %TypeCheck.Builtin.NamedType{name: name, type: type}
  end
end
