defmodule TypeCheck.Builtin do
  require TypeCheck.Internals.ToTypespec
  # TypeCheck.Internals.ToTypespec.define_all()

  def any() do
    %TypeCheck.Builtin.Any{}
  end
  def term(), do: any()

  def atom() do
    %TypeCheck.Builtin.Atom{}
  end
  def module(), do: atom()

  def as_boolean(type) do
    TypeCheck.Type.ensure_type!(type)
    type
  end

  def arity() do
    range(0..255)
  end

  def binary() do
    %TypeCheck.Builtin.Binary{}
  end

  def bitstring() do
    %TypeCheck.Builtin.Bitstring{}
  end

  def boolean() do
    %TypeCheck.Builtin.Boolean{}
  end

  def byte() do
    range(0..255)
  end

  def char() do
    range(0..0x10FFFF)
  end

  def charlist() do
    list(char())
  end

  def function() do
    %TypeCheck.Builtin.Function{}
  end

  def fun() do
    function()
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

  def mfa() do
    tuple_of([module(), atom(), arity()])
  end

  @type tuple_of(_list_of_elements) :: tuple()

  def tuple_of(list_of_element_types)
  # prevents double-expanding
  # when called as `tuple_of([1,2,3])` by the user.
  def tuple_of(list = %TypeCheck.Builtin.FixedList{}) do
    tuple_of(list.element_types)
  end

  def tuple_of(element_types_list) when is_list(element_types_list) do
    Enum.map(element_types_list, &TypeCheck.Type.ensure_type!/1)

    %TypeCheck.Builtin.Tuple{element_types: element_types_list}
  end

  def tuple(size) when is_integer(size) do
    elems =
      0..size
      |> Enum.map(fn -> any() end)
    tuple_of(elems)
  end

  def literal(value) do
    %TypeCheck.Builtin.Literal{value: value}
  end

  def left | right do
    one_of(left, right)
  end

  def one_of(left, right)

  # Prevents nesting
  # for nicer error messages on failure.
  def one_of(left = %TypeCheck.Builtin.OneOf{}, right = %TypeCheck.Builtin.OneOf{}) do
    one_of(left.choices ++ right.choices)
  end

  def one_of(left = %TypeCheck.Builtin.OneOf{}, right) do
    one_of(left.choices ++ [right])
  end

  def one_of(left, right = %TypeCheck.Builtin.OneOf{}) do
    one_of([left] ++ right.choices)
  end
  def one_of(left, right) do
    one_of([left, right])
  end

  def one_of(list_of_possibilities)

  def one_of(list = %TypeCheck.Builtin.FixedList{}) do
    one_of(list.element_types)
  end

  def one_of(list_of_possibilities) when is_list(list_of_possibilities) do
    # IO.inspect(list_of_possibilities, label: :asd, structs: false)
    # Enum.map(list_of_possibilities, &TypeCheck.Type.ensure_type!/1)

    %TypeCheck.Builtin.OneOf{choices: list_of_possibilities}
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

  # prevents double-expanding
  # when called as `fixed_map([a: 1, b: 2])` by the user.
  def fixed_map(list = %TypeCheck.Builtin.FixedList{}) do
    list.element_types
    |> Enum.map(fn
      %TypeCheck.Builtin.Tuple{element_types: element_types} when length(element_types) == 2 ->
        {hd(element_types), hd(tl(element_types))}
      tuple = %TypeCheck.Builtin.Tuple{element_types: element_types} when length(element_types) != 2 ->
        raise "Improper type passed to `fixed_map/1` #{inspect(tuple)}"
      thing ->
        TypeCheck.Type.ensure_type!(thing)
    end)
    |> fixed_map()
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

    # Make sure the type contains coherent names.
    TypeCheck.Builtin.Guarded.extract_names(type)

    %TypeCheck.Builtin.Guarded{type: type, guard: guard_ast}
  end
end
