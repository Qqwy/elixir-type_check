defmodule TypeCheck.Builtin do
  @moduledoc """
  Contains TypeCheck specifications for all 'built-in' Elixir types.

  These are all the types described on the ['Basic Types', 'Literals' and 'Builtin Types' sections of the Elixir 'Typespecs' documentation page.](https://hexdocs.pm/elixir/typespecs.html#basic-types)

  See `TypeCheck.DefaultOverrides` for the 'Remote Types' supported by TypeCheck.

  Usually you'd want to import this module when you're using TypeCheck.
  This is done automatically when calling `use TypeCheck`.

  If necessary, feel free to hide (using `import ... except: `)
  the things you don't need.

  ### Ommissions

  TypeCheck strives to implement all of the syntax and builtin types
  which Elixir itself also supports.
  Most of them are supported today.
  The rest will hopefully be supported in the near future.

  For an up-to-date comparison of what types TypeCheck
  does and does not support w.r.t. Elixir's builtin typespecs,
  see [Comparison to Plain Typespecs](comparing-typecheck-and-elixir-typespecs.html).


  """

  require TypeCheck.Internals.ToTypespec
  # TypeCheck.Internals.ToTypespec.define_all()

  import TypeCheck.Internals.Bootstrap.Macros

  if_recompiling? do
    use TypeCheck
  end

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
  if_recompiling? do
    @spec any() :: TypeCheck.Builtin.Any.t()
  end

  def any() do
    build_struct(TypeCheck.Builtin.Any)
  end

  @doc typekind: :builtin
  @doc "alias for `any/0`"
  if_recompiling? do
    @spec term() :: TypeCheck.Builtin.Any.t()
  end

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
  if_recompiling? do
    @spec atom() :: TypeCheck.Builtin.Atom.t()
  end

  def atom() do
    build_struct(TypeCheck.Builtin.Atom)
  end

  @doc typekind: :builtin
  @doc """
  Any Elixir atom,
  but indicates that the atom
  is expected to be used as a module.

      iex> TypeCheck.conforms!(String, module())
      String
      iex> TypeCheck.conforms!(:array, module())
      :array
      iex> TypeCheck.conforms!("hello", module())
      ** (TypeCheck.TypeError) `"hello"` is not an atom.

  c.f. `atom/0`
  """
  if_recompiling? do
    @spec module() :: TypeCheck.Builtin.Atom.t()
  end

  def module(), do: atom()

  @doc typekind: :builtin
  @doc """
  The same as `type`,
  but indicates that the result will be used
  as a boolean.

      iex> TypeCheck.conforms!(:ok, as_boolean(atom()))
      :ok
      iex> TypeCheck.conforms!(10, as_boolean(atom()))
      ** (TypeCheck.TypeError) `10` is not an atom.
  """
  if_recompiling? do
    @spec as_boolean(t :: TypeCheck.Type.t()) :: TypeCheck.Type.t()
  end

  def as_boolean(type) do
    TypeCheck.Type.ensure_type!(type)
    type
  end

  @doc typekind: :builtin
  @doc """
  Shorthand for `range(0..255)`

      iex> TypeCheck.conforms!(1, arity())
      1
      iex> TypeCheck.conforms!(1000, arity())
      ** (TypeCheck.TypeError) `1000` does not check against `0..255`. Reason:
            `1000` falls outside the range 0..255.
  """
  if_recompiling? do
    @spec arity() :: TypeCheck.Builtin.Range.t()
  end

  def arity() do
    range(0..255)
  end

  @doc typekind: :builtin
  @doc """
  Any binary.

  A binary is a bitstring with a bitsize divisible by eight.

  c.f. `TypeCheck.Builtin.Binary`
  """
  if_recompiling? do
    @spec binary() :: TypeCheck.Builtin.Binary.t()
  end

  def binary() do
    build_struct(TypeCheck.Builtin.Binary)
  end

  @doc typekind: :builtin
  @doc """
  A binary which contains at least one byte.

  Shorthand for `sized_bitstring(8, 8)`.
  """
  if_recompiling? do
    @spec nonempty_binary() :: TypeCheck.Builtin.SizedBitstring.t()
  end

  def nonempty_binary() do
    sized_bitstring(8, 8)
  end

  @doc typekind: :builtin
  @doc """
  Any bitstring

  c.f. `TypeCheck.Builtin.Bitstring`
  """
  if_recompiling? do
    @spec bitstring() :: TypeCheck.Builtin.Bitstring.t()
  end

  def bitstring() do
    build_struct(TypeCheck.Builtin.Bitstring)
  end

  @doc typekind: :builtin
  @doc """
  A bitstring which contains at least one bit.

  Shorthand for `sized_bitstring(1, 1)`.
  """
  if_recompiling? do
    @spec nonempty_bitstring() :: TypeCheck.Builtin.SizedBitstring.t()
  end

  def nonempty_bitstring() do
    sized_bitstring(1, 1)
  end

  @doc typekind: :builtin
  @doc """
  Any boolean

  (either `true` or `false`.)

  c.f. `TypeCheck.Builtin.Boolean`
  """
  if_recompiling? do
    @spec boolean() :: TypeCheck.Builtin.Boolean.t()
  end

  def boolean() do
    build_struct(TypeCheck.Builtin.Boolean)
  end

  @doc typekind: :builtin
  @doc """
  A byte; shorthand for `range(0..255)`

  c.f. `range/1`

      iex> TypeCheck.conforms!(1, byte())
      1
      iex> TypeCheck.conforms!(255, byte())
      255
      iex> TypeCheck.conforms!(256, byte())
      ** (TypeCheck.TypeError) `256` does not check against `0..255`. Reason:
            `256` falls outside the range 0..255.
  """
  if_recompiling? do
    @spec byte() :: TypeCheck.Builtin.Range.t()
  end

  def byte() do
    range(0..255)
  end

  @doc typekind: :builtin
  @doc """
  A char; shorthand for `range(0..0x10FFFF)`

  c.f. `range/1`

      iex> TypeCheck.conforms!(?a, char())
      97
      iex> TypeCheck.conforms!(-1, char())
      ** (TypeCheck.TypeError) `-1` does not check against `0..1114111`. Reason:
            `-1` falls outside the range 0..1114111.
  """
  if_recompiling? do
    @spec char() :: TypeCheck.Builtin.Range.t()
  end

  def char() do
    range(0..0x10FFFF)
  end

  @doc typekind: :builtin
  @doc """
  A list filled with characters; exactly `list(char())`

  c.f. `list/1` and `char/0`

      iex> TypeCheck.conforms!('hello world', charlist())
      'hello world'
      iex> TypeCheck.conforms!("hello world", charlist())
      ** (TypeCheck.TypeError) `"hello world"` does not check against `list(0..1114111)`. Reason:
            `"hello world"` is not a list.
  """
  if_recompiling? do
    @spec charlist() :: TypeCheck.Builtin.List.t(TypeCheck.Builtin.Range.t())
  end

  def charlist() do
    list(char())
  end

  @doc typekind: :builtin
  @doc """
  Any function (of any arity), regardless of input or output types

  c.f. `TypeCheck.Builtin.Function`

      iex> TypeCheck.conforms!(&div/2, function())
      &:erlang.div/2
      iex> TypeCheck.conforms!(&Application.get_env/3, function())
      &Application.get_env/3
      iex> TypeCheck.conforms!(42, function())
      ** (TypeCheck.TypeError) `42` is not a function.
  """
  if_recompiling? do
    @spec function() :: TypeCheck.Builtin.Function.t()
  end

  def function() do
    build_struct(TypeCheck.Builtin.Function)
  end

  @doc typekind: :builtin
  @doc """
  A function (of any arity) returning `return_type`.

  Desugaring of `(... -> return_type)`

  See `function/2` for more info.

  c.f. `TypeCheck.Builtin.Function`
  """
  if_recompiling? do
    @spec function(return_type :: TypeCheck.Type.t()) :: TypeCheck.Builtin.Function.t()
  end

  def function(return_type) do
    build_struct(TypeCheck.Builtin.Function)
    |> Map.put(:return_type, return_type)
  end

  @doc typekind: :builtin
  @doc """
  A function taking `param_types` as parameters, returning `return_type`.

  Desugaring of `(param_type -> return_type)`,
  `(param_type, param_type2 -> return_type)`,
  `(param_type, param_type2, param_type3 -> return_type)` etc.

  Type-checking a function value against a function-type works a bit differently from most other types.
  The reason for this is that we can only ascertain whether the function-value works correctly when the function-value is called.

  Specifically:
  - When a call to `TypeCheck.conforms/3` (and variants) or a function wrapped with a `@spec` is called, we can immediately check whether a particular parameter:
    - is a function
    - accepts the expected arity
  - Then, the parameter-which-is-a-function is wrapped in a 'wrapper function' which, when called:
    - typechecks whether the passed parameters are of the expected types (_This checks whether *your* function uses the parameter-function correctly_.)
    - calls the original function with the parameters.
    - typechecks whether the result is of the expected type. (_This checks whether the *parameter-function* works correctly_.)
    - returns the result.

  In other words, the 'wrapper function' which is added for a type `(param_type, param_type2 -> result_type)` works similarly
  to a named function with the spec `@spec myfunction(param_type, param_type2) :: result_type`.

      iex> # The following passes the first check...
      iex> fun = TypeCheck.conforms!(&div/2, (integer(), integer() -> boolean()))
      iex> # ... but once the function returns, the wrapper will raise
      iex> fun.(20, 5)
      ** (TypeCheck.TypeError) The call to `#Function<...>/2` failed,
          because the returned result does not adhere to the spec `boolean()`.
          Rather, its value is: `4`.
          Details:
            The result of calling `#Function<...>.(20, 5)`
            does not adhere to spec `(integer(), integer() -> boolean())`. Reason:
              Returned result:
                `4` is not a boolean.

  c.f. `TypeCheck.Builtin.Function`
  """
  if_recompiling? do
    @spec function(
            param_types :: TypeCheck.Builtin.List.t(TypeCheck.Type.t()),
            return_type :: TypeCheck.Type.t()
          ) ::
            TypeCheck.Builtin.Function.t()
  end

  def function(param_types, return_type) do
    build_struct(TypeCheck.Builtin.Function)
    |> Map.put(:param_types, param_types)
    |> Map.put(:return_type, return_type)
  end

  @doc typekind: :builtin
  @doc """
  Alias for `function/0`.

      iex> TypeCheck.conforms!(&div/2, fun())
      &:erlang.div/2
  """
  if_recompiling? do
    @spec fun() :: TypeCheck.Builtin.Function.t()
  end

  def fun() do
    function()
  end

  @doc typekind: :builtin
  @doc """
  Any integer.

  C.f. `TypeCheck.Builtin.Integer`

      iex> TypeCheck.conforms!(42, integer())
      42

      iex> TypeCheck.conforms!(42.0, integer())
      ** (TypeCheck.TypeError) `42.0` is not an integer.

      iex> TypeCheck.conforms!("hello", integer())
      ** (TypeCheck.TypeError) `"hello"` is not an integer.
  """
  if_recompiling? do
    @spec integer() :: TypeCheck.Builtin.Integer.t()
  end

  def integer() do
    build_struct(TypeCheck.Builtin.Integer)
  end

  @doc typekind: :builtin
  @doc """
  Any integer smaller than zero.

  C.f. `TypeCheck.Builtin.NegInteger`
  """
  if_recompiling? do
    @spec neg_integer() :: TypeCheck.Builtin.NegInteger.t()
  end

  def neg_integer() do
    build_struct(TypeCheck.Builtin.NegInteger)
  end

  @doc typekind: :builtin
  @doc """
  Any integer zero or larger.

  C.f. `TypeCheck.Builtin.NonNegInteger`
  """
  if_recompiling? do
    @spec non_neg_integer() :: TypeCheck.Builtin.NonNegInteger.t()
  end

  def non_neg_integer() do
    build_struct(TypeCheck.Builtin.NonNegInteger)
  end

  @doc typekind: :builtin
  @doc """
  Any integer larger than zero.

  C.f. `TypeCheck.Builtin.PosInteger`
  """
  if_recompiling? do
    @spec pos_integer() :: TypeCheck.Builtin.PosInteger.t()
  end

  def pos_integer() do
    build_struct(TypeCheck.Builtin.PosInteger)
  end

  @doc typekind: :builtin
  @doc """
  Any float.

  C.f. `TypeCheck.Builtin.Float`
  """
  if_recompiling? do
    @spec float() :: TypeCheck.Builtin.Float.t()
  end

  def float() do
    build_struct(TypeCheck.Builtin.Float)
  end

  @doc typekind: :builtin
  @doc """
  Any number (either a float or an integer)

  Matches the same as `integer | float` but is more efficient.

  C.f. `TypeCheck.Builtin.Number`
  """
  if_recompiling? do
    @spec number() :: TypeCheck.Builtin.Number.t()
  end

  def number() do
    build_struct(TypeCheck.Builtin.Number)
  end

  @doc typekind: :builtin
  @doc """
  Builtin type. Syntactic sugar for `:infinity | non_neg_integer()`
  """
  def timeout() do
    one_of([literal(:infinity), non_neg_integer()])
  end

  @doc typekind: :builtin
  @doc """
  A (proper) list with any type of elements;

  shorthand for `list(any())`

  C.f. `list/1` and `any/0`
  """
  if_recompiling? do
    @spec list() :: TypeCheck.Builtin.List.t(TypeCheck.Builtin.Any.t())
  end

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
  if_recompiling? do
    @spec list(a :: TypeCheck.Type.t()) :: TypeCheck.Builtin.List.t(TypeCheck.Type.t())
  end

  def list(a) do
    build_struct(TypeCheck.Builtin.List)
    |> Map.put(:element_type, a)
  end

  @doc typekind: :builtin
  @doc """
  A list of pairs with atoms as 'keys' and anything allowed as as 'values'.

  Shorthand for `list({atom(), any()})`

      iex> x = [a: 1, b: 2]
      iex> TypeCheck.conforms!(x, keyword())
      [a: 1, b: 2]

      iex> y = [a: 1, b: 2] ++ [3, 4]
      iex> TypeCheck.conforms!(y, keyword())
      ** (TypeCheck.TypeError) `[{:a, 1}, {:b, 2}, 3, 4]` does not check against `list({atom(), any()})`. Reason:
            at index 2:
              `3` does not check against `{atom(), any()}`. Reason:
                `3` is not a tuple.
  """
  if_recompiling? do
    @spec keyword() :: TypeCheck.Builtin.List.t(TypeCheck.Builtin.FixedTuple.t())
  end

  def keyword() do
    keyword(any())
  end

  @doc typekind: :builtin
  @doc """
  Syntactic sugar for `maybe_improper_list(any(), any())`
  """
  def maybe_improper_list() do
    maybe_improper_list(any(), any())
  end

  @doc typekind: :builtin
  @doc """
  WIP
  """
  if_recompiling? do
    @spec maybe_improper_list(element :: TypeCheck.Type.t(), terminator :: TypeCheck.Type.t()) ::
            TypeCheck.Builtin.MaybeImproperList.t()
  end

  def maybe_improper_list(element_type, terminator_type) do
    build_struct(TypeCheck.Builtin.MaybeImproperList)
    |> Map.put(:element_type, element_type)
    |> Map.put(:terminator_type, terminator_type)
  end

  @doc typekind: :builtin
  @doc """
  A list of pairs with atoms as 'keys' and t's as 'values'.

  Shorthand for `list({atom(), t})`
  """
  if_recompiling? do
    @spec keyword(a :: TypeCheck.Type.t()) ::
            TypeCheck.Builtin.List.t(TypeCheck.Builtin.FixedTuple.t())
  end

  def keyword(t) do
    list(fixed_tuple([atom(), t]))
  end

  @doc typekind: :builtin
  @doc """
  A module-function-arity tuple

  - Module is a `module/0`
  - function is an `atom/0`
  - Arity is an `arity/0`

  C.f. `fixed_tuple/1`
  """
  if_recompiling? do
    @spec mfa() :: TypeCheck.Builtin.FixedTuple.t()
  end

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
  if_recompiling? do
    @spec fixed_tuple(types :: TypeCheck.Builtin.List.t(TypeCheck.Type.t())) ::
            TypeCheck.Builtin.FixedTuple.t()
  end

  def fixed_tuple(list_of_element_types)
  # prevents double-expanding
  # when called as `fixed_tuple([1,2,3])` by the user.
  # This is also the reason for the indirection here
  def fixed_tuple(list = %{__struct__: TypeCheck.Builtin.FixedList}) do
    do_fixed_tuple(list.element_types)
  end

  def fixed_tuple(element_types_list) when is_list(element_types_list) do
    do_fixed_tuple(element_types_list)
  end

  if_recompiling? do
    @spec do_fixed_tuple(types :: TypeCheck.Builtin.List.t(TypeCheck.Type.t())) ::
            TypeCheck.Builtin.FixedTuple.t()
  end

  defp do_fixed_tuple(element_types_list) do
    build_struct(TypeCheck.Builtin.FixedTuple)
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
  if_recompiling? do
    @spec tuple(size :: TypeCheck.Builtin.NonNegInteger.t()) :: TypeCheck.Builtin.FixedTuple.t()
  end

  def tuple(0), do: fixed_tuple([])

  def tuple(size) when is_integer(size) and size > 0 do
    elems =
      1..size
      |> Enum.map(fn _ -> any() end)

    fixed_tuple(elems)
  end

  @doc typekind: :builtin
  @doc """
  A tuple of any size (with any elements).

  C.f. `TypeCheck.Builtin.Tuple`
  """
  if_recompiling? do
    @spec tuple() :: TypeCheck.Builtin.Tuple.t()
  end

  def tuple() do
    build_struct(TypeCheck.Builtin.Tuple)
  end

  @doc typekind: :builtin
  @doc """
  A literal value.

  Desugaring of using any literal primitive value
  (like a particular integer, float, atom, binary or bitstring)
  directly a type.

  For instance, `10` desugars to `literal(10)`.

  Represented in Elixir's builtin Typespecs as
  - for integers, atoms and booleans: the primitive value itself.
  - for binaries, a more general `binary()` is used
    as Elixir's builtin typespecs do not support literal UTF-8 binaries as literal values.
  - For other kinds of values which Elixir's builtin typespecs do not support as literals,
    we similarly represent it as a more general type.

  C.f. `TypeCheck.Builtin.Literal`
  """
  if_recompiling? do
    @spec literal(a :: TypeCheck.Builtin.Any.t()) :: %TypeCheck.Builtin.Literal{}
  end

  def literal(value) do
    build_struct(TypeCheck.Builtin.Literal)
    |> Map.put(:value, value)
  end

  @doc typekind: :builtin
  @doc """
  A union of multiple types (also known as a 'sum type')

  Desugaring of types separated by `|` like `a | b` or `a | b | c | d`.
  (and represented that way in Elixir's builtin Typespecs).
  """
  if_recompiling? do
    @spec one_of(left :: TypeCheck.Type.t(), right :: TypeCheck.Type.t()) :: TypeCheck.Type.t()
  end

  def one_of(left, right), do: one_of([left, right])

  @doc typekind: :builtin
  @doc """
  Version of `one_of` that allows passing many possibilities
  at once.

  A union of multiple types (also known as a 'sum type')

  Desugaring of types separated by `|` like `a | b` or `a | b | c | d`.
  (and represented that way in Elixir's builtin Typespecs).

  c.f. `one_of/2`.
  """
  if_recompiling? do
    @spec one_of(types :: TypeCheck.Builtin.List.t(TypeCheck.Type.t())) :: TypeCheck.Type.t()
  end

  def one_of(list_of_possibilities)

  # Fix double expansion
  def one_of(list = %{__struct__: TypeCheck.Builtin.FixedList}) do
    one_of(list.element_types)
  end

  def one_of(types) when is_list(types) do
    # unwrap nested unions
    types =
      types
      |> Enum.flat_map(fn
        %{__struct__: TypeCheck.Builtin.OneOf, choices: types} -> types
        type -> [type]
      end)
      |> Enum.uniq()

    cond do
      length(types) == 1 ->
        List.first(types)

      Enum.any?(types, &match?(%{__struct__: TypeCheck.Builtin.Any}, &1)) ->
        any()

      true ->
        build_struct(TypeCheck.Builtin.OneOf) |> Map.put(:choices, types)
    end
  end

  @doc typekind: :builtin
  @doc """
  Any integer in the half-open range `range`.

  Desugaring of `a..b`.
  (And represented that way in Elixir's builtin Typespecs.)

  C.f. `TypeCheck.Builtin.Range`
  """
  if_recompiling? do
    # TODO!
    @spec range(range :: Range.t()) :: TypeCheck.Builtin.Range.t()
  end

  def range(range = _lower.._higher) do
    # %TypeCheck.Builtin.Range{range: range}

    build_struct(TypeCheck.Builtin.Range)
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
  if_recompiling? do
    @spec range(lower :: integer(), higher :: integer()) :: TypeCheck.Builtin.Range.t()
  end

  def range(lower, higher)

  def range(%{__struct__: TypeCheck.Builtin.Literal, value: lower}, %{
        __struct__: TypeCheck.Builtin.Literal,
        value: higher
      }) do
    range(lower, higher)
  end

  def range(lower, higher) do
    build_struct(TypeCheck.Builtin.Range)
    |> Map.put(:range, lower..higher)
  end

  @doc typekind: :builtin
  @doc """
  Any Elixir map with any types as keys and any types as values.

  C.f. `TypeCheck.Builtin.Map`
  """

  if_recompiling? do
    @spec map() :: TypeCheck.Builtin.Map.t()
  end

  def map() do
    build_struct(TypeCheck.Builtin.Map)
    |> Map.put(:key_type, any())
    |> Map.put(:value_type, any())
  end

  @doc typekind: :builtin
  @doc """
  Any map containing zero or more keys of `key_type` and values of `value_type`.

  Represented in Elixir's builtin Typespecs as `%{optional(key_type) => value_type}`,
  and indeed a desugaring of this.

  Note that multiple optional keypairs are not (yet) supported.

  C.f. `TypeCheck.Builtin.Map`
  """
  if_recompiling? do
    @spec map(key_type :: TypeCheck.Type.t(), value_type :: TypeCheck.Type.t()) ::
            TypeCheck.Builtin.Map.t()
  end

  def map(key_type, value_type) do
    TypeCheck.Type.ensure_type!(key_type)
    TypeCheck.Type.ensure_type!(value_type)

    build_struct(TypeCheck.Builtin.Map)
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
  if_recompiling? do
    @spec fixed_map(key_value_type_pairs :: keyword()) :: TypeCheck.Builtin.FixedMap.t()
  end

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
      %{__struct__: TypeCheck.Builtin.FixedTuple, element_types: element_types}
      when length(element_types) == 2 ->
        {hd(element_types), hd(tl(element_types))}

      tuple = %{__struct__: TypeCheck.Builtin.FixedTuple, element_types: element_types}
      when length(element_types) != 2 ->
        raise TypeCheck.CompileError, "Improper type passed to `fixed_map/1` #{inspect(tuple)}"

      thing ->
        TypeCheck.Type.ensure_type!(thing)
    end)
    |> fixed_map()
  end

  def fixed_map(keywords) when is_map(keywords) or is_list(keywords) do
    # Note: Keys are expected to be any literal term.
    # This does _not_ need to be wrapped in an extra call to `literal/1`.
    Enum.each(keywords, fn {_key, value} ->
      TypeCheck.Type.ensure_type!(value)
    end)

    build_struct(TypeCheck.Builtin.FixedMap)
    |> Map.put(:keypairs, Enum.into(keywords, []))
  end

  @doc typekind: :extension
  @doc """
  Allows constructing map types containing a combination of fixed, required and optional keys (and their associatied type-values)

  Desugaring of most ways of map syntaxes.

  Note that because of reasons of efficiency and implementation difficulty,
  not all possibilities are supported by TypeCheck currently.

  Supported are:
  - maps with only fixed keys (`%{a: 1, b: 2, "foo" => number()}`)
  - maps with a single required keypair (`%{required(key_type) => value_type}`)
  - maps with a single optional keypair (`%{optional(key_type) => value_type}`)
  - maps with only fixed keys and one optional keypair (`%{:a => 1, :b => 2, "foo" => number(), optional(integer()) => boolean()}`)

  Help with extending this support is very welcome.
  c.f. https://github.com/Qqwy/elixir-type_check/issues/7
  """

  if_recompiling? do
    @spec fancy_map(
            fixed_kvs ::
              TypeCheck.Builtin.List.t({TypeCheck.Builtin.Any.t(), TypeCheck.Type.t()}),
            required_kvs :: TypeCheck.Builtin.List.t({TypeCheck.Type.t(), TypeCheck.Type.t()}),
            optional_kvs :: TypeCheck.Builtin.List.t({TypeCheck.Type.t(), TypeCheck.Type.t()})
          ) ::
            TypeCheck.Builtin.CompoundFixedMap.t()
            | TypeCheck.Builtin.FixedMap.t()
            | TypeCheck.Builtin.Map.t()
            | TypeCheck.Builtin.NamedType.t()
  end

  def fancy_map(fixed_kvs, required_kvs, optional_kvs)

  def fancy_map(fixed_keypairs, [], []) do
    fixed_map(fixed_keypairs)
  end

  def fancy_map([], [], [{optional_key_type, value_type}]) do
    map(optional_key_type, value_type)
  end

  def fancy_map([], [{required_key_type, value_type}], []) do
    required_map(required_key_type, value_type)
  end

  def fancy_map(fixed_keypairs, [], optionals) do
    fixed = fixed_map(fixed_keypairs)

    flexible =
      case optionals do
        [{optional_key_type, value_type}] ->
          map(optional_key_type, value_type)

        optionals when is_list(optionals) and length(optionals) > 0 ->
          # check whether all optionals have literal keys
          check_result =
            Enum.reduce_while(optionals, [], fn
              {%{__struct__: TypeCheck.Builtin.Literal, value: key}, type}, acc ->
                {:cont, [{key, type} | acc]}

              _, _acc ->
                {:halt, :unsupported}
            end)

          case check_result do
            :unsupported ->
              raise_unsupported_map_error()

            keypairs when is_list(keypairs) ->
              build_struct(TypeCheck.Builtin.OptionalFixedMap)
              |> Map.put(:keypairs, keypairs)
          end
      end

    build_struct(TypeCheck.Builtin.CompoundFixedMap)
    |> Map.put(:fixed, fixed)
    |> Map.put(:flexible, flexible)
  end

  defp required_map(required_key_type, value_type) do
    guard =
      quote do
        map_size(unquote(Macro.var(:map, nil))) >= 1
      end

    named_type(:map, map(required_key_type, value_type))
    |> guarded_by(guard)
  end

  defp raise_unsupported_map_error do
    raise """
    TODO!
    Maps with complex combinations of multiple
    fixed and/or required(...) and/or optional(...) keypairs
    are not currently supported by TypeCheck.

    Supported are:
    - maps with only fixed keys (`%{a: 1, b: 2, "foo" => number()}`)
    - maps with a single required keypair (`%{required(key_type) => value_type}`)
    - maps with a single optional keypair (`%{optional(key_type) => value_type}`)
    - maps with only fixed keys and zero or more optional literal keypairs (`%{:a => 1, :b => 2, optional(:foo) => boolean(), optional(:bar) => boolean()}`)
    - maps with only fixed keys and one optional non-literal keypair (`%{:a => 1, :b => 2, "foo" => number(), optional(integer()) => boolean()}`)

    Help with extending this support is very welcome.
    c.f. https://github.com/Qqwy/elixir-type_check/issues/7
    """
  end

  @doc typekind: :builtin
  @doc """
  Any kind of struct.

  Syntactic sugar for %{:__struct__ => atom(), optional(atom()) => any()}
  """
  def struct() do
    fancy_map([__struct__: atom()], [], [{atom(), any()}])
  end

  @doc typekind: :extension
  @doc """
  A list of fixed size where `element_types` dictates the types
  of each of the respective elements.

  Desugaring of literal lists like `[:a, 10, "foo"]`.

  Cannot directly be represented in Elixir's builtin Typespecs,
  and is thus represented as `[any()]` instead.
  """
  if_recompiling? do
    @spec fixed_list(element_types :: TypeCheck.Builtin.List.t(TypeCheck.Type.t())) ::
            TypeCheck.Builtin.FixedList.t()
  end

  def fixed_list(element_types)

  # prevents double-expanding
  # when called as `fixed_list([1,2,3])` by the user.
  def fixed_list(list = %{__struct__: TypeCheck.Builtin.FixedList}) do
    list
  end

  def fixed_list(element_types) do
    do_fixed_list(element_types)
  end

  if_recompiling? do
    @spec do_fixed_list(element_types :: TypeCheck.Builtin.List.t(TypeCheck.Type.t())) ::
            TypeCheck.Builtin.FixedList.t()
  end

  defp do_fixed_list(element_types) do
    build_struct(TypeCheck.Builtin.FixedList)
    |> Map.put(:element_types, element_types)
  end

  @doc typekind: :builtin
  @doc """
  A bitstring of fixed size.

  Desugaring of bitstring types like `<< _ :: size>>`.

  c.f. `TypeCheck.Builtin.SizedBitstring`.
  """
  if_recompiling? do
    @spec sized_bitstring(prefix_size :: TypeCheck.Builtin.NonNegInteger.t()) ::
            TypeCheck.Builtin.SizedBitstring.t()
  end

  def sized_bitstring(size) do
    sized_bitstring(size, nil)
  end

  @doc typekind: :builtin
  @doc """
  A bitstring with a fixed `prefix_size` (which might be `0`), followed by zero or repetitions of `unit_size`.

  Desugaring of bitstring types like `<< _ :: _ * unit_size>>` and `<< _ :: prefix_size, _ :: _ * unit_size>>`.

      iex> TypeCheck.conforms!("hi", <<_ :: 16>>)
      "hi"

      iex> TypeCheck.conforms!("bye", <<_ :: 16>>)
      ** (TypeCheck.TypeError) `"bye"` has a different bit_size (24) than expected (16).

      iex> TypeCheck.conforms!(<<1 :: size(2)>>, <<_ :: 2>>)
      <<1 :: size(2)>>

      iex> TypeCheck.conforms!(<<1 :: size(3)>>, <<_ :: 2>>)
      ** (TypeCheck.TypeError) `<<1::size(3)>>` has a different bit_size (3) than expected (2).

      iex> ["ab", "abcd", "abcdef"] |> Enum.map(&TypeCheck.conforms!(&1, <<_ :: _ * 16>>))
      ["ab", "abcd", "abcdef"]

      iex> TypeCheck.conforms!("abc",  <<_ :: _ * 16>>)
      ** (TypeCheck.TypeError) `"abc"` has a different bit_size (24) than expected (_ * 16).

      iex> ["a", "abc", "abcde"] |> Enum.map(&TypeCheck.conforms!(&1, <<_ :: 8, _ :: _ * 16>>))
      ["a", "abc", "abcde"]

      iex> TypeCheck.conforms!("ab",  <<_ :: 8, _ :: _ * 16>>)
      ** (TypeCheck.TypeError) `"ab"` has a different bit_size (16) than expected (8 + _ * 16).


  c.f. `TypeCheck.Builtin.SizedBitstring`.
  """
  if_recompiling? do
    @spec sized_bitstring(
            prefix_size :: TypeCheck.Builtin.NonNegInteger.t(),
            unit_size :: nil | 1..256
          ) ::
            TypeCheck.Builtin.SizedBitstring.t()
  end

  def sized_bitstring(prefix_size, unit_size) do
    build_struct(TypeCheck.Builtin.SizedBitstring)
    |> Map.put(:prefix_size, prefix_size)
    |> Map.put(:unit_size, unit_size)
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
  if_recompiling? do
    # @spec named_type(name :: atom() | String.t(), type :: TypeCheck.Type.t()) :: TypeCheck.Builtin.NamedType.t()
  end

  def named_type(name, type, type_kind \\ :type, called_as \\ nil) do
    TypeCheck.Type.ensure_type!(type)

    build_struct(TypeCheck.Builtin.NamedType)
    |> Map.put(:name, name)
    |> Map.put(:type, type)
    |> Map.put(:local, true)
    |> Map.put(:type_kind, type_kind)
    |> Map.put(:called_as, called_as)
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
  if_recompiling? do
    @spec guarded_by(
            type :: TypeCheck.Type.t(),
            ast :: TypeCheck.Builtin.Any.t(),
            original_module :: TypeCheck.Builtin.Atom.t() | nil
          ) :: TypeCheck.Builtin.Guarded.t()
  end

  def guarded_by(type, guard_ast, module \\ nil) do
    # Make sure the type contains coherent names.
    TypeCheck.Builtin.Guarded.extract_names(type)

    build_struct(TypeCheck.Builtin.Guarded)
    |> Map.put(:type, type)
    |> Map.put(:guard, guard_ast)
    |> Map.put(:original_module, module)
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
  if_recompiling? do
    @spec lazy(ast :: TypeCheck.Type.t()) :: TypeCheck.Builtin.Lazy.t()
  end

  defmacro lazy(type_call_ast) do
    typecheck_options =
      Module.get_attribute(__CALLER__.module, TypeCheck.Options, TypeCheck.Options.new())

    expanded_call =
      TypeCheck.Internals.PreExpander.rewrite(type_call_ast, __CALLER__, typecheck_options)

    {module, name, arguments} =
      case Macro.decompose_call(expanded_call) do
        {name, arguments} ->
          module = find_matching_module(__CALLER__, name, length(arguments))
          {module, name, arguments}

        other ->
          other
      end

    # Used in the 'ToTypespec' conversion
    # to use original type information when removing `lazy`.
    {:lazy_explicit, meta, args} =
      quote generated: true, location: :keep do
        lazy_explicit(unquote(module), unquote(name), unquote(arguments))
      end

    meta = meta |> Keyword.put(:original_type_ast, type_call_ast)
    {:lazy_explicit, meta, args}
  end

  defp find_matching_module(caller, name, arity) do
    Enum.find(caller.functions, {caller.module, []}, fn {_module, functions_with_arities} ->
      Enum.any?(functions_with_arities, &(&1 == {name, arity}))
    end)
    |> elem(0)
  end

  @doc false
  def lazy_explicit(module, function, arguments) do
    build_struct(TypeCheck.Builtin.Lazy)
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
    build_struct(TypeCheck.Builtin.None)
  end

  @doc typekind: :builtin
  @doc """
  See `none/0`.
  """
  def no_return(), do: none()

  @doc typekind: :builtin
  @doc """
  Matches any process-identifier.

  Note that no checks are made to see whether the process is alive or not.

  Also, the current property-generator will generate arbitrary PIDs, most of which
  will not point to alive processes.
  """
  if_recompiling? do
    @spec pid() :: TypeCheck.Builtin.PID.t()
  end

  def pid() do
    build_struct(TypeCheck.Builtin.PID)
  end

  @doc typekind: :builtin
  @doc """
  Matches any reference.

  c.f. `TypeCheck.Builtin.Reference`

      iex> TypeCheck.conforms?(Kernel.make_ref(), reference())
      true
      iex> some_ref = IEx.Helpers.ref(0, 749884137, 111673345, 43386)
      ...> TypeCheck.conforms!(some_ref, reference())
      #Reference<0.749884137.111673345.43386>
  """
  if_recompiling? do
    @spec reference() :: TypeCheck.Builtin.Reference.t()
  end

  def reference() do
    build_struct(TypeCheck.Builtin.Reference)
  end

  @doc typekind: :builtin
  @doc """
  Matches any port.

  c.f. `TypeCheck.Builtin.Port`

      iex> TypeCheck.conforms?(Kernel.make_ref(), reference())
      true
      iex> some_port = Port.open({:spawn, "cat"}, [:binary])
      ...> TypeCheck.conforms?(some_port, port())
      true
  """
  if_recompiling? do
    @spec port() :: TypeCheck.Builtin.Port.t()
  end

  def port() do
    build_struct(TypeCheck.Builtin.Port)
  end

  @doc typekind: :builtin
  @doc """
  Syntactic sugar for `pid() | port() | reference()`

      iex> TypeCheck.conforms?(self(), identifier())
      true
  """
  def identifier() do
    named_type(
      :identifier,
      one_of([pid(), port(), reference()])
    )
  end

  @doc typekind: :builtin
  @doc """
  A nonempty_list is any list with at least one element.
  """
  def nonempty_list(type) do
    guard =
      quote do
        unquote(Macro.var(:non_empty_list, nil)) != []
      end

    guarded_by(named_type(:non_empty_list, list(type)), guard)
  end

  @doc typekind: :builtin
  @doc """
  Shorthand for nonempty_list(any()).
  """
  def nonempty_list() do
    nonempty_list(any())
  end

  @doc typekind: :builtin
  @doc """
  Shorthand for nonempty_list(char()).
  """
  def nonempty_charlist() do
    nonempty_list(char())
  end

  @doc typekind: :builtin
  @doc """
  Any list with at least one element, which might be terminated by something else than `[]`.

  To be precise, the list needs to be terminated with either `[]` or `terminator_type`
  """
  def nonempty_maybe_improper_list(element_type, terminator_type) do
    guard =
      quote do
        unquote(Macro.var(:nonempty_maybe_improper_list, nil)) != []
      end

    guarded_by(
      named_type(
        :nonempty_maybe_improper_list,
        maybe_improper_list(element_type, terminator_type)
      ),
      guard
    )
  end

  @doc typekind: :builtin
  @doc """
  Any list with at least one element, which has to be terminated by something else than `[]`.

  To be precise, the list needs to be terminated with `terminator_type`.
  """
  def nonempty_improper_list(element_type, terminator_type) do
    guard =
      quote do
        Builtin.improper_list?(unquote(Macro.var(:nonempty_improper_list, nil)))
      end

    guarded_by(
      named_type(:nonempty_improper_list, maybe_improper_list(element_type, terminator_type)),
      guard
    )
  end

  @doc false
  def improper_list?([]), do: false
  def improper_list?([_head | tail]), do: improper_list?(tail)
  def improper_list?(_terminator), do: true

  @doc """
  A potentially-improper list containing binaries,
  single characters, or nested iolists.

  Syntactic sugar for `maybe_improper_list(byte() | binary() | iolist(), binary() | []) `
  """
  @doc typekind: :builtin
  def iolist() do
    element = one_of([byte(), binary(), lazy(iolist())])
    terminator = one_of([binary(), []])
    maybe_improper_list(element, terminator)
  end

  @doc typekind: :builtin
  @doc """
  Syntactic sugar for `binary() | iolist()`
  """
  def iodata() do
    one_of([binary(), iolist()])
  end

  @doc typekind: :extension
  @doc """
  Checks whether the given value implements the particular protocol.


  For this type-check to work, [Protocol Consolidation](https://hexdocs.pm/elixir/Protocol.html#module-consolidation) needs to be active.

  ## Data generation

  TypeCheck tries to generate values of any type implementing the protocol.
  These generators can generate any built-in type for which the protocol is implemented (with the exception of functions, and datetimes).

  It can also generate your custom structs, as long as:

  - They contain a TypeCheck type called `t`.
    In this case, any values adhering to `t` will be generated.
  - They don't have a `t` TypeCheck type, but contain a `new/0` function.
    In this case, a single value is generated each time: the result of calling `YourStructModule.new/0`.

  A deliberate choice was made not to automatically generate values for any module by using `struct/0`,
  because this would not respect the `@enforce_keys` option that might be given to structs.
  """
  if_recompiling? do
    @spec impl(protocol_name :: TypeCheck.Builtin.Atom.t()) ::
            TypeCheck.Builtin.ImplementsProtocol.t()
  end

  def impl(protocol_name) when is_atom(protocol_name) do
    build_struct(TypeCheck.Builtin.ImplementsProtocol)
    |> Map.put(:protocol, protocol_name)
  end

  # Reason we cannot dirctly use %module{}
  # is because then we'd create circular dependencies.
  defp build_struct(module) do
    Macro.struct!(module, __ENV__)
  end
end
