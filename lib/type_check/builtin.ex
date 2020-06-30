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
    TypeCheck.Type.ensure_type!(a)
    %TypeCheck.Builtin.List{element_type: a}
  end

  # prevents double-expanding
  # when called as `tuple([1,2,3])` by the user.
  def tuple(list = %TypeCheck.Builtin.FixedList{}) do
    tuple(list.element_types)
  end

  def tuple(element_types_list) when is_list(element_types_list) do
    Enum.map(element_types_list, &TypeCheck.Type.ensure_type!/1)

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
    TypeCheck.Type.ensure_type!(left)
    TypeCheck.Type.ensure_type!(right)

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
    TypeCheck.Type.ensure_type!(key_type)
    TypeCheck.Type.ensure_type!(value_type)

    %TypeCheck.Builtin.Map{key_type: key_type, value_type: value_type}
  end

  def fixed_map(keywords)

  # prevents double-expanding
  # when called as `fixed_map(%{a: 1, b: 2})` by the user.
  def fixed_map(map = %TypeCheck.Builtin.FixedMap{}) do
    map
  end

  def fixed_map(keywords) when is_map(keywords) or is_list(keywords) do
    Enum.map(keywords, &TypeCheck.Type.ensure_type!(elem(&1, 1)))

    %TypeCheck.Builtin.FixedMap{keypairs: Enum.into(keywords, [])}
  end


  def fixed_list(element_types)

  # prevents double-expanding
  # when called as `fixed_list([1,2,3])` by the user.
  def fixed_list(list = %TypeCheck.Builtin.FixedList{}) do
    list
  end

  def fixed_list(element_types) when is_list(element_types) do
    Enum.map(element_types, &TypeCheck.Type.ensure_type!/1)

    %TypeCheck.Builtin.FixedList{element_types: element_types}
  end

  def named_type(name, type) do
    TypeCheck.Type.ensure_type!(type)

    %TypeCheck.Builtin.NamedType{name: name, type: type}
  end

  # TODO maybe add a check to make it work correctly
  # when someone calls it manually?
  def guarded_by(type, guard_ast) do
    TypeCheck.Type.ensure_type!(type)

    %TypeCheck.Builtin.Guarded{type: type, guard: guard_ast}
  end
end
