defmodule TypeCheck.Builtin do
  require TypeCheck.Internals.ToTypespec
  # TypeCheck.Internals.ToTypespec.define_all()

  @moduledoc """

  Usually you'd want to import this module when you're using TypeCheck.
  Feel free to import only the things you need,
  or hide (using `import ... except: `) the things you don't.
  """

  @doc typekind: :builtin
  @doc """
  Any Elixir value.

  Will always succeed.

  c.f. `TypeCheck.Builtin.Any`


      iex> TypeCheck.conforms!(10, any())
      10
      iex> TypeCheck.conforms!("foobar", any())
      "foobar"

  """
  def any() do
    Macro.struct!(TypeCheck.Builtin.Any, __ENV__)
  end

  @doc typekind: :builtin
  @doc "alias for `any/0`"
  def term(), do: any()

  @doc typekind: :builtin
  @doc """
  Any Elixir atom.

  c.f. `TypeCheck.Builtin.Atom`

      iex> TypeCheck.conforms!(:ok, atom())
      :ok
      iex> TypeCheck.conforms!(:foo, atom())
      :foo
      iex> TypeCheck.conforms!(10, atom())
      ** (TypeCheck.TypeError) `10` is not an atom.
  """
  def atom() do
    Macro.struct!(TypeCheck.Builtin.Atom, __ENV__)
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
    Macro.struct!(TypeCheck.Builtin.Binary, __ENV__)
  end

  @doc typekind: :builtin
  @doc """
  Any bitstring

  c.f. `TypeCheck.Builtin.Bitstring`
  """
  def bitstring() do
   Macro.struct!(TypeCheck.Builtin.Bitstring, __ENV__)
  end

  @doc typekind: :builtin
  @doc """
  Any boolean

  (either `true` or `false`.)

  c.f. `TypeCheck.Builtin.Boolean`
  """
  def boolean() do
    Macro.struct!(TypeCheck.Builtin.Boolean, __ENV__)
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
    Macro.struct!(TypeCheck.Builtin.Function, __ENV__)
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
    Macro.struct!(TypeCheck.Builtin.Integer, __ENV__)
  end

  @doc typekind: :builtin
  @doc """
  Any integer smaller than zero.

  C.f. `TypeCheck.Builtin.NegInteger`
  """
  def neg_integer() do
    Macro.struct!(TypeCheck.Builtin.NegInteger, __ENV__)
  end

  @doc typekind: :builtin
  @doc """
  Any integer zero or larger.

  C.f. `TypeCheck.Builtin.NonNegInteger`
  """
  def non_neg_integer() do
    Macro.struct!(TypeCheck.Builtin.NonNegInteger, __ENV__)
  end

  @doc typekind: :builtin
  @doc """
  Any integer larger than zero.

  C.f. `TypeCheck.Builtin.PosInteger`
  """
  def pos_integer() do
    Macro.struct!(TypeCheck.Builtin.PosInteger, __ENV__)
  end

  @doc typekind: :builtin
  @doc """
  Any float.

  C.f. `TypeCheck.Builtin.Float`
  """
  def float() do
    Macro.struct!(TypeCheck.Builtin.Float, __ENV__)
  end

  @doc typekind: :builtin
  @doc """
  Any number (either a float or an integer)

  Matches the same as `integer | float` but is more efficient.

  C.f. `TypeCheck.Builtin.Number`
  """
  def number() do
    Macro.struct!(TypeCheck.Builtin.Number, __ENV__)
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


      iex> TypeCheck.conforms!([1,2,3], list(integer()))
      [1,2,3]

      iex> TypeCheck.conforms!(:foo, list(integer()))
      ** (TypeCheck.TypeError) `:foo` does not check against `list(integer())`. Reason:
        `:foo` is not a list.

      iex> TypeCheck.conforms!([1, 2, 3.3], list(integer()))
      ** (TypeCheck.TypeError) `[1, 2, 3.3]` does not check against `list(integer())`. Reason:
        at index 2:
          `3.3` is not an integer.
  """
  def list(a) do
    TypeCheck.Type.ensure_type!(a)
    Macro.struct!(TypeCheck.Builtin.List, __ENV__)
    |> Map.put(:element_type, a)
  end
  @doc typekind: :builtin
  @doc """
  A module-function-arity tuple

  - Module is a `module/0`
  - function is an `atom/0`
  - Arity is an `arity/0`

  C.f. `fixed_tuple/1`
  """
  def mfa() do
    fixed_tuple([module(), atom(), arity()])
  end

  @doc typekind: :builtin
  @doc """
  A tuple whose elements are of the types given by `list_of_element_types`.

  Desugaring of writing tuples directly in your types:
  `{a, b, c}` desugars to `fixed_tuple([a, b, c])`.

  Represented in Elixir's builtin Typespecs as a plain tuple,
  where each of the elements are the respective element of `list_of_types`.

  C.f. `TypeCheck.Builtin.Tuple`
  """
  def fixed_tuple(list_of_element_types)
  # prevents double-expanding
  # when called as `fixed_tuple([1,2,3])` by the user.
  def fixed_tuple(list = %{__struct__: TypeCheck.Builtin.FixedList}) do
    fixed_tuple(list.element_types)
  end

  def fixed_tuple(element_types_list) when is_list(element_types_list) do
    Enum.map(element_types_list, &TypeCheck.Type.ensure_type!/1)

    Macro.struct!(TypeCheck.Builtin.FixedTuple, __ENV__)
    |> Map.put(:element_types, element_types_list)
  end

  @doc typekind: :extension
  @doc """
  A tuple whose elements have any types,
  but which has exactly `size` elements.

  Represented in Elixir's builtin Typespecs as a plain tuple,
  with `size` elements, where each of the element types
  is `any()`.

  For instance, `tuple(3)` is represented as `{any(), any(), any()}`.
  """
  def tuple(size) when is_integer(size) do
    elems =
      0..size
      |> Enum.map(fn -> any() end)
    fixed_tuple(elems)
  end

  @doc typekind: :builtin
  @doc """
  A tuple of any size (with any elements).

  C.f. `TypeCheck.Builtin.Tuple`
  """
  def tuple() do
    Macro.struct!(TypeCheck.Builtin.Tuple, __ENV__)
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
    # %TypeCheck.Builtin.Literal{value: value}

    Macro.struct!(TypeCheck.Builtin.Literal, __ENV__)
    |> Map.put(:value, value)
  end

  @doc false
  def left | right do
    one_of(left, right)
  end

  @doc typekind: :builtin
  @doc """
  A union of multiple types (also known as a 'sum type')

  Desugaring of types separated by `|` like `a | b` or `a | b | c | d`.
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

  @doc typekind: :builtin
  @doc """
  Version of `one_of` that allows passing many possibilities
  at once.

  A union of multiple types (also known as a 'sum type')

  Desugaring of types separated by `|` like `a | b` or `a | b | c | d`.
  (and represented that way in Elixir's builtin Typespecs).

  c.f. `one_of/2`.
  """
  def one_of(list_of_possibilities)

  def one_of(list = %{__struct__: TypeCheck.Builtin.FixedList}) do
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
    # %TypeCheck.Builtin.Range{range: range}

    Macro.struct!(TypeCheck.Builtin.Range, __ENV__)
    |> Map.put(:range, range)
  end

  def range(%{__struct__: TypeCheck.Builtin.Literal, value: val = %Range{}}) do
    range(val)
  end

  @doc typekind: :builtin
  @doc """
  Any integer between `lower` (includsive) and `higher` (exclusive).

  Desugaring of `lower..higher`.
  (And represented that way in Elixir's builtin Typespecs.)

  C.f. `range/1`
  """
  def range(lower, higher)

  def range(%{__struct__: TypeCheck.Builtin.Literal, value: lower}, %{__struct__: TypeCheck.Builtin.Literal, value: higher}) do
    range(lower, higher)
  end
  def range(lower, higher) do
    # %TypeCheck.Builtin.Range{range: lower..higher}

    Macro.struct!(TypeCheck.Builtin.Range, __ENV__)
    |> Map.put(:range, lower..higher)
  end

  @doc typekind: :builtin
  @doc """
  Any Elixir map with any types as keys and any types as values.

  C.f. `TypeCheck.Builtin.Map`
  """
  def map() do
    Macro.struct!(TypeCheck.Builtin.Map, __ENV__)
    |> Map.put(:key_type, any())
    |> Map.put(:value_type, any())
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

    Macro.struct!(TypeCheck.Builtin.Map, __ENV__)
    |> Map.put(:key_type, key_type)
    |> Map.put(:value_type, value_type)
  end

  @doc typekind: :builtin
  @doc """
  A map with exactly the key-value-pairs indicated by `keywords`

  where all keys are required to be literal values,
  and the values are a type specification.

  Desugaring of literal maps like `%{a_key: value_type, "other_key" => value_type2}`.

  Represented in Elixir's builtin Typespecs as
  ```
  %{required(:a_key) => value_type1, required("other key") => value_type2}
  ```.
  (for e.g. a call to `fixed_map([a_key: value_type1, {"other key", value_type2}])`)
  """
  def fixed_map(keywords)

  # prevents double-expanding
  # when called as `fixed_map(%{a: 1, b: 2})` by the user.
  def fixed_map(map = %{__struct__: TypeCheck.Builtin.FixedMap}) do
    map
  end

  # prevents double-expanding
  # when called as `fixed_map([a: 1, b: 2])` by the user.
  def fixed_map(list = %{__struct__: TypeCheck.Builtin.FixedList}) do
    list.element_types
    |> Enum.map(fn
      %{__struct__: TypeCheck.Builtin.FixedTuple, element_types: element_types} when length(element_types) == 2 ->
        {hd(element_types), hd(tl(element_types))}
      tuple = %{__struct__: TypeCheck.Builtin.FixedTuple, element_types: element_types} when length(element_types) != 2 ->
        raise "Improper type passed to `fixed_map/1` #{inspect(tuple)}"
      thing ->
        TypeCheck.Type.ensure_type!(thing)
    end)
    |> fixed_map()
  end

  def fixed_map(keywords) when is_map(keywords) or is_list(keywords) do
    Enum.map(keywords, &TypeCheck.Type.ensure_type!(elem(&1, 1)))

    Macro.struct!(TypeCheck.Builtin.FixedMap, __ENV__)
    |> Map.put(:keypairs, Enum.into(keywords, []))
  end

  @doc typekind: :extension
  @doc """
  A list of fixed size where `element_types` dictates the types
  of each of the respective elements.

  Desugaring of literal lists like `[:a, 10, "foo"]`.

  Cannot directly be represented in Elixir's builtin Typespecs,
  and is thus represented as `[any()]` instead.
  """
  def fixed_list(element_types)

  # prevents double-expanding
  # when called as `fixed_list([1,2,3])` by the user.
  def fixed_list(list = %{__struct__: TypeCheck.Builtin.FixedList}) do
    list
  end

  def fixed_list(element_types) when is_list(element_types) do
    Enum.map(element_types, &TypeCheck.Type.ensure_type!/1)

    Macro.struct!(TypeCheck.Builtin.FixedList, __ENV__)
    |> Map.put(:element_types, element_types)
  end

  @doc typekind: :extension
  @doc """
  A type with a local name, which can be referred to from a 'type guard'.

  This name can be used in 'type guards'.
  See the module documentation and `guarded_by/2` for more information.

  Desugaring of `name :: type` (when `::` is used _inside_ a type.).

  Cannot directly be represented in Elixir's builtin Typespecs,
  and is thus represented as `type` (without the name) instead.
  """
  def named_type(name, type) do
    TypeCheck.Type.ensure_type!(type)

    Macro.struct!(TypeCheck.Builtin.NamedType, __ENV__)
    |> Map.put(:name, name)
    |> Map.put(:type, type)
  end

  @doc typekind: :extension
  @doc """
  Adds a 'type guard' to the type, which is an extra check
  written using arbitrary Elixir code.

  Desugaring of `some_type when guard_code`.

  The type guard is a check written using any Elixir code,
  which may refer to names set in the type using `named_type/2`.

  If this type guard fails (by returning a non-truthy value),
  the type will not check.

  For user-friendly error-handling, don't let your type guards
  throw exceptions.

  C.f. `TypeCheck.Builtin.Guarded`

  Cannot be represented in Elixir's builtin Typespecs,
  and is thus represented as `type` (without the guard) instead.
  """
  def guarded_by(type, guard_ast) do
    TypeCheck.Type.ensure_type!(type)

    # Make sure the type contains coherent names.
    TypeCheck.Builtin.Guarded.extract_names(type)

    %TypeCheck.Builtin.Guarded{type: type, guard: guard_ast}
  end

  @doc typekind: :extension
  @doc """
  Defers type-expansion until the last possible moment.

  This is used to be able to expand recursive types.

  For instance, if you have the following:

  ```
  defmodule MyBrokenlist do
    type empty :: nil
    type cons(a) :: {a, mylist(a)}
    type mylist(a) :: empty() | cons(a)

    spec new_list() :: mylist(any())
    def new_list() do
      nil
    end

    spec cons_val(mylist(any()), any()) :: mylist(any)
    def cons_val(list, val) do
      {val, list}
    end
  end
  ```

  then when `TypeCheck` is expanding the `spec`s at compile-time
  to build the type-checking code, `mylist(a)` will call `cons(a)`
  which will call `mylist(a)` which will call `cons(a)` etc. until infinity.
  This makes compilation hang indefinitely.

  To be able to handle types like this, use `lazy`:


  ```
  defmodule MyFixedList do
    type empty :: nil
    type cons(a) :: {a, lazy(mylist(a))}
    type mylist(a) :: empty() | cons(a)

    spec new_list() :: mylist(any())
    def new_list() do
      nil
    end

    spec cons_val(mylist(any()), any()) :: mylist(any)
    def cons_val(list, val) do
      {val, list}
    end
  end
  ```

  This will work as intended.

  Since `lazy/1` defers type-expansion (and check-code-generation) until
  runtime, the compiler is not able to optimize the type-checking code.

  Thus, you should only use it when necessary, since it will be slower
  than when using the inner type direcly.


  ### In builtin typespecs


  `lazy/1` does not exist in Elixir's builtin typespecs
  (since builtin typespecs does not expand types it does not need to handle
  recursive types in a special way).
  Therefore, `lazy(some_type)` is represented
  as `some_type` directly in ELixir's builtin typespecs.
  """
  defmacro lazy(type_call_ast) do
    expanded_call = TypeCheck.Internals.PreExpander.rewrite(type_call_ast, __CALLER__)
    {module, name, arguments} =
      case Macro.decompose_call(expanded_call) do
        {name, arguments} ->
          module = find_matching_module(__CALLER__, name, length(arguments))
          {module, name, arguments}
        other -> other
      end
    quote location: :keep do
      lazy_explicit(unquote(module), unquote(name), unquote(arguments))
    end
  end

  defp find_matching_module(caller, name, arity) do
    Enum.find(caller.functions, {caller.module, []}, fn {_module, functions_with_arities} ->
      Enum.any?(functions_with_arities, &(&1 == {name, arity}))
    end)
    |> elem(0)
  end

  @doc false
  def lazy_explicit(module, function, arguments) do
    Macro.struct!(TypeCheck.Builtin.Lazy, __ENV__)
    |> Map.merge(%{module: module, function: function, arguments: arguments})
  end

  @doc typekind: :builtin
  @doc """
  Matches no value at all.

  `none()` is not very useful on its own,
  but it is a useful default in certain circumstances,
  as well as to indicate that you expect some place to not return at all.
  (instead for instance throwing an exception or looping forever.)

  C.f. `TypeCheck.Builtin.None`.
  """
  def none() do
    Macro.struct!(TypeCheck.Builtin.None, __ENV__)
  end
  @doc typekind: :builtin
  @doc """
  See `none/0`.
  """
  def no_return(), do: none()
end
