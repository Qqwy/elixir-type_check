defmodule TypeCheck.Builtin do
  require TypeCheck.Internals.ToTypespec
  # TypeCheck.Internals.ToTypespec.define_all()

  @moduledoc """
  """

  @doc typekind: :builtin
  @doc """
  Any Elixir value.

  Will always succeed.

  c.f. `TypeCheck.Builtin.Any`
  """
  def any() do
    %TypeCheck.Builtin.Any{}
  end

  @doc typekind: :builtin
  @doc "alias for `any/0`"
  def term(), do: any()

  @doc typekind: :builtin
  @doc """
  Any Elixir atom.

  c.f. `TypeCheck.Builtin.Atom`
  """
  def atom() do
    %TypeCheck.Builtin.Atom{}
  end

  @doc typekind: :builtin
  @doc """
  Any Elixir atom,
  but indicates that the atom
  is expected to be used as a module.

  c.f. `atom/0`
  """
  def module(), do: atom()

  @doc typekind: :builtin
  @doc """
  The same as `type`,
  but indicates that the result will be used
  as a boolean.
  """
  def as_boolean(type) do
    TypeCheck.Type.ensure_type!(type)
    type
  end

  @doc typekind: :builtin
  @doc """
  Shorthand for `range(0..255)`
  """
  def arity() do
    range(0..255)
  end

  @doc typekind: :builtin
  @doc """
  Any binary.

  A binary is a bitstring with a bitsize divisible by eight.

  c.f. `TypeCheck.Builtin.Binary`
  """
  def binary() do
    %TypeCheck.Builtin.Binary{}
  end

  @doc typekind: :builtin
  @doc """
  Any bitstring

  c.f. `TypeCheck.Builtin.Bitstring`
  """
  def bitstring() do
    %TypeCheck.Builtin.Bitstring{}
  end

  @doc typekind: :builtin
  @doc """
  Any boolean

  (either `true` or `false`.)

  c.f. `TypeCheck.Builtin.Boolean`
  """
  def boolean() do
    %TypeCheck.Builtin.Boolean{}
  end

  @doc typekind: :builtin
  @doc """
  A byte; shorthand for `range(0..255)`

  c.f. `range/1`
  """
  def byte() do
    range(0..255)
  end

  @doc typekind: :builtin
  @doc """
  A char; shorthand for `range(0..0x10FFFF)`

  c.f. `range/1`
  """
  def char() do
    range(0..0x10FFFF)
  end

  @doc typekind: :builtin
  @doc """
  A list filled with characters; exactly `list(char())`

  c.f. `list/1` and `char/0`
  """
  def charlist() do
    list(char())
  end

  @doc typekind: :builtin
  @doc """
  Any function (of any arity), regardless of input or output types

  c.f. `TypeCheck.Builtin.Function`
  """
  def function() do
    %TypeCheck.Builtin.Function{}
  end

  @doc typekind: :builtin
  @doc """
  Alias for `function/0`.
  """
  def fun() do
    function()
  end

  @doc typekind: :builtin
  @doc """
  Any integer.

  C.f. `TypeCheck.Builtin.Integer`
  """
  def integer() do
    %TypeCheck.Builtin.Integer{}
  end

  @doc typekind: :builtin
  @doc """
  Any float.

  C.f. `TypeCheck.Builtin.Integer`
  """
  def float() do
    %TypeCheck.Builtin.Float{}
  end

  @doc typekind: :builtin
  @doc """
  A (proper) list with any type of elements;

  shorthand for `list(any())`

  C.f. `list/1` and `any/0`
  """
  def list() do
    list(any())
  end

  @doc typekind: :builtin
  @doc """
  A (proper) list containing only elements of type `a`.

  C.f. `TypeCheck.Builtin.List`
  """
  def list(a) do
    TypeCheck.Type.ensure_type!(a)
    %TypeCheck.Builtin.List{element_type: a}
  end
  @doc typekind: :builtin
  @doc """
  A module-function-arity tuple

  - Module is a `module/0`
  - function is an `atom/0`
  - Arity is an `arity/0`

  C.f. `tuple_of/1`
  """
  def mfa() do
    tuple_of([module(), atom(), arity()])
  end

  @type tuple_of(_list_of_elements) :: tuple()

  @doc typekind: :builtin
  @doc """
  A tuple whose elements are of the types given by `list_of_element_types`.

  Desugaring of writing tuples directly in your types:
  `{a, b, c}` desugars to `tuple_of([a, b, c])`.

  Represented in Elixir's builtin Typespecs as a plain tuple,
  where each of the elements are the respective element of `list_of_types`.

  C.f. `TypeCheck.Builtin.Tuple`
  """
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

  @doc typekind: :builtin
  @doc """
  A literal value.

  Desugaring of using any literal primitive value
  (like a particular integer, float, atom, binary or bitstring)
  directly a type.

  For instance, `10` desugars to `literal(10)`.

  Represented in Elixir's builtin Typespecs as the primitive value itself.

  C.f. `TypeCheck.Builtin.Literal`
  """
  def literal(value) do
    %TypeCheck.Builtin.Literal{value: value}
  end

  @doc false
  def left | right do
    one_of(left, right)
  end

  @doc typekind: :builtin
  @doc """
  A union of multiple types (also known as a 'sum type')

  Desugaring of `a | b` and `a | b | c | d`.
  (and represented that way in Elixir's builtin Typespecs).
  """
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
    %TypeCheck.Builtin.OneOf{choices: list_of_possibilities}
  end

  @doc typekind: :builtin
  @doc """
  Any integer in the half-open range `range`.

  Desugaring of `a..b`.
  (And represented that way in Elixir's builtin Typespecs.)

  C.f. `TypeCheck.Builtin.Range`
  """
  def range(range = _lower.._higher) do
    %TypeCheck.Builtin.Range{range: range}
  end

  @doc typekind: :builtin
  @doc """
  Any integer between `lower` (includsive) and `higher` (exclusive).

  Desugaring of `lower..higher`.
  (And represented that way in Elixir's builtin Typespecs.)

  C.f. `range/1`
  """
  def range(lower, higher) do
    %TypeCheck.Builtin.Range{range: lower..higher}
  end

  @doc typekind: :builtin
  @doc """
  Any Elixir map with any types as keys and any types as values.

  C.f. `TypeCheck.Builtin.Map`
  """
  def map() do
    %TypeCheck.Builtin.Map{key_type: any(), value_type: any()}
  end

  @doc typekind: :extension
  @doc """
  Any map containing zero or more keys of `key_type` and values of `value_type`.

  Represented in Elixir's builtin Typespecs as `%{optional(key_type) => value_type}`.

  C.f. `TypeCheck.Builtin.Map`
  """
  def map(key_type, value_type) do
    TypeCheck.Type.ensure_type!(key_type)
    TypeCheck.Type.ensure_type!(value_type)

    %TypeCheck.Builtin.Map{key_type: key_type, value_type: value_type}
  end

  @doc typekind: :builtin
  @doc """
  A map with exactly the key-value-pairs indicated by `keywords`

  where all keys are required to be literal values,
  and the values are a type specification.

  Desugaring of `%{key: value_type, "other_key" => value_type2}`.

  Represented in Elixir's builtin Typespecs as
  `%{required(:key1) => value_type1, required("other key") => value_type2}`.
  (for e.g. a call to `fixed_map([key1: value_type1, {"other key", value_type2}])`)
  """
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

  def guarded_by(type, guard_ast) do
    TypeCheck.Type.ensure_type!(type)

    # Make sure the type contains coherent names.
    TypeCheck.Builtin.Guarded.extract_names(type)

    %TypeCheck.Builtin.Guarded{type: type, guard: guard_ast}
  end
end
