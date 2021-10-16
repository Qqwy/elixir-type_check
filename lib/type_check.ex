defmodule TypeCheck do
  require TypeCheck.Type

  @moduledoc """
  Fast and flexible runtime type-checking.

  The main way to use TypeCheck is by adding `use TypeCheck` in your modules.
  This will allow you to use the macros of `TypeCheck.Macros` in your module,
  which are versions of the normal type-specification module attributes
  with an extra exclamation mark at the end:  `@type!`, `@spec!`, `@typep!` and `@opaque!`.


  It will also bring all functions in `TypeCheck.Builtin` in scope,
  which is usually what you want as this allows you to
  use all types and special syntax that are built-in to Elixir
  in the TypeCheck specifications.


  Using these, you're able to add function-specifications to your functions
  which will wrap them with runtime type-checks.
  You'll also be able to create your own type-specifications that can be used
  in other type- and function-specifications in the same or other modules later on:

      defmodule User do
        use TypeCheck
        defstruct [:name, :age]
        @type! age :: non_neg_integer()
        @type! t :: %User{name: binary(), age: age()}

        @spec! new(binary(), age()) :: t()
        def new(name, age) do
          %User{name: name, age: age}
        end

        @spec! old_enough?(t(), age()) :: boolean()
        def old_enough?(user, limit) do
          user.age >= limit
        end
      end

  Finally, you can test whether your functions correctly adhere to their specs,
  by adding a `spectest` in your testing suite. See `TypeCheck.ExUnit.spectest/2` for details.

  ## Types and their syntax

  TypeCheck allows types written using (essentially) the same syntax as [Elixir's builtin typespecs](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).
  This means the following:

  - literal values like `:ok`, `10.0` or `"my string"` desugar to a call to `TypeCheck.Builtin.literal/1`, which is a type that matches only exactly that value.
  - Basic types like `integer()`, `float()`, `atom()` etc. are directly supported (and exist as functions in `TypeCheck.Builtin`).
  - tuples of types like `{atom(), integer()}` are supported (and desugar to `TypeCheck.Builtin.fixed_tuple/1`)
  - maps where keys are literal values and the values are types like `%{a: integer(), b: integer(), 42 => float()}` desugar to calls to `TypeCheck.Builtin.fixed_map/1`.
    - The same happens with structs like `%User{name: binary(), age: non_neg_integer()}`
  - sum types like `integer() | string() | atom()` are supported, and desugar to calls to `TypeCheck.Builtin.one_of/1`.
  - Ranges like `lower..higher` are supported, matching integers within the given range. This desugars into a call to `TypeCheck.Builtin.range/1`.

  ### Currently unsupported features

  The following typespec syntax can _not_ currently be used in TypeCheck. This will hopefully change in future versions of the library.

  - Binary pattern-matches containing size-references like `<<_ :: size>>`.
  - (Anonymous) function types like `( -> result_type)` and `(type1, type2 -> result_type)`.
  - Shorthand nonempty list syntax (`[some_type, ...]`)
  - Literal maps with `required(...)` and `optional(...)` keys. (TypeCheck does already support literal maps with a fixed set of keys, as well as maps with any number of key-value-pairs of fixed types. It is the special syntax that might mix these approaches that is not supported yet.)

  ### Extensions

  TypeCheck adds the following extensions on Elixir's builtin typespec syntax:


  - fixed-size lists containing types like `[1, 2, integer()]` are supported, and desugar to `TypeCheck.Builtin.fixed_list/1`.
    This example matches only lists of 3 elements where the first element is the literal `1`, the second the literal `2` and the last element any integer.
    Elixir's builtin typespecs do not support fixed-size lists.
  - named types like `x :: integer()` are supported; these are useful in combination with "type guards" (see the section below).
  - "type guards" using the syntax `some_type when arbitrary_code` are supported, to add extra arbitrary checks to a value for it to match the type. (See the section about type guards below.)
  - `lazy(some_type)`, which defers type-expansion until during runtime. This is required to be able to expand recursive types. C.f. `TypeCheck.Builtin.lazy/1`

  ## Named Types Type Guards

  To add extra custom checks to a type, you can use a so-called 'type guard'.
  This is arbitrary code that is executed during a type-check once the type itself already matches.

  You can use "named types" to refer to (parts of) the value that matched the type, and refer to these from a type-guard:

  ```
  type sorted_pair :: {lower :: number(), higher :: number()} when lower <= higher
  ```

      iex> TypeCheck.conforms!({10, 20}, sorted_pair)
      {10, 20}
      iex> TypeCheck.conforms!({20, 10}, sorted_pair)
      ** (TypeCheck.TypeError) `{20, 10}` does not match the definition of the named type `TypeCheckTest.TypeGuardExample.sorted_pair`
          which is: `TypeCheckTest.TypeGuardExample.sorted_pair
          ::
          (sorted_pair :: {lower :: number(), higher :: number()} when lower <= higher)`. Reason:
            `{20, 10}` does not check against `(sorted_pair :: {lower :: number(), higher :: number()} when lower <= higher)`. Reason:
              type guard:
                `lower <= higher` evaluated to false or nil.
                bound values: %{higher: 10, lower: 20, sorted_pair: {20, 10}}

  Named types are available in your guard even from the (both local and remote) types that you are using in your time, as long as those types are not defined as _opaque_ types.


  ## Manual type-checking

  If you want to check values against a type _outside_ of the checks the `@spec!` macro
  wraps a function with,
  you can use the `conforms/2`/`conforms?/2`/`conforms!/2` macros in this module directly in your code.

  These are evaluated _at compile time_ which means the resulting checks will be optimized by the compiler.
  Unfortunately it also means that the types passed to them have to be known at compile time.

  If you have a type that is constructed dynamically at runtime, you can resort to
  `dynamic_conforms/2` and variants.
  Because these variants have to evaluate the type-checking code at runtime,
  these checks are not optimized by the compiler.

  ### Introspection

  To allow checking what types and specs exist,
  the introspection function `__type_check__/1` will be added to a module when `use TypeCheck` is used.

  - `YourModule.__type_check__(:types)` returns a keyword list of all `{type_name, arity}`
    pairs for all types defined in the module using `@type!`/`@typep!` or `@opaque!`.
  - `YourModule.__type_check__(:specs)` returns a keyword list of all `{function_name, arity}`
    pairs for all functions in the module wrapped with a spec using `@spec!`.

  Note that these lists might also contain private types / private function names.
  """

  defmacro __using__(options) do
    case __CALLER__.module do
      nil ->
        quote generated: true, location: :keep do
          require TypeCheck
          require TypeCheck.Type
          import TypeCheck.Builtin
          :ok
        end
      _other ->
        quote generated: true, location: :keep do
          use TypeCheck.Macros, unquote(options)
          require TypeCheck
          require TypeCheck.Type
          import TypeCheck.Builtin
          :ok
        end
    end
  end

  @doc """
  Makes sure `value` typechecks the type description `type`.

  If it typechecks, we return `{:ok, value}`
  Otherwise, we return `{:error, %TypeCheck.TypeError{}}` which contains information
  about why the value failed the check.

  `conforms` is a macro and expands the type check at compile-time,
  allowing it to be optimized by the compiler.

  C.f. `TypeCheck.Type.build/1` for more information on what type-expressions
  are allowed as `type` parameter.

  Note: _usually_ you'll want to `import TypeCheck.Builtin` in the context where you use `conforms`,
  which will bring Elixir's builtin types into scope.
  (Calling `use TypeCheck` will already do this; see the module documentation of `TypeCheck` for more information))
  """
  @type value :: any()
  # Note: Below spec highlights how the macro functions when it is _used_:
  @spec conforms(value, TypeCheck.Type.expandable_type()) ::
          {:ok, value} | {:error, TypeCheck.TypeError.t()}
  defmacro conforms(value, type, options \\ Macro.escape(TypeCheck.Options.new())) do
    {evaluated_options, _} = Code.eval_quoted(options, [], __CALLER__)

    evaluated_options = TypeCheck.Options.new(evaluated_options)
    type = TypeCheck.Type.build_unescaped(type, __CALLER__, evaluated_options)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)

    res = quote generated: true, location: :keep do
      case unquote(check) do
        {:ok, bindings, altered_value} -> {:ok, altered_value}
        {:error, problem} -> {:error, TypeCheck.TypeError.exception({problem, unquote(Macro.Env.location(__CALLER__))})}
      end
    end

    if(evaluated_options.debug) do
      TypeCheck.Internals.Helper.prettyprint_spec("TypeCheck.conforms(#{inspect(value)}, #{inspect(type)}, #{inspect(options)})", res)
    end
    res
  end

  @doc """
  Similar to `conforms/2`, but returns `true` if the value typechecked and `false` if it did not.

  The same features and restrictions apply to this function as to `conforms/2`.
  """
  @spec conforms?(value, TypeCheck.Type.expandable_type()) :: boolean()
  defmacro conforms?(value, type, options \\ Macro.escape(TypeCheck.Options.new())) do
    {evaluated_options, _} = Code.eval_quoted(options, [], __CALLER__)

    evaluated_options = TypeCheck.Options.new(evaluated_options)
    type = TypeCheck.Type.build_unescaped(type, __CALLER__, evaluated_options)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)

    res = quote generated: true, location: :keep do
      match?({:ok, _, _}, unquote(check))
    end

    if(evaluated_options.debug) do
      TypeCheck.Internals.Helper.prettyprint_spec("TypeCheck.conforms?(#{inspect(value)}, #{inspect(type)}, #{inspect(options)})", res)
    end

    res
  end

  @doc """
  Similar to `conforms/2`, but returns `value` if the value typechecked and raises TypeCheck.TypeError if it did not.

  The same features and restrictions apply to this function as to `conforms/2`.
  """
  @spec conforms!(value, TypeCheck.Type.expandable_type()) :: value | no_return()
  defmacro conforms!(value, type, options \\ Macro.escape(TypeCheck.Options.new())) do
    {evaluated_options, _} = Code.eval_quoted(options, [], __CALLER__)

    evaluated_options = TypeCheck.Options.new(evaluated_options)
    type = TypeCheck.Type.build_unescaped(type, __CALLER__, evaluated_options)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)

    res = quote generated: true, location: :keep do
      case unquote(check) do
        {:ok, _bindings, altered_value} -> altered_value
        {:error, other} -> raise TypeCheck.TypeError, other
      end
    end

    if(evaluated_options.debug) do
      TypeCheck.Internals.Helper.prettyprint_spec("TypeCheck.conforms!(#{inspect(value)}, #{inspect(type)}, #{inspect(options)})", res)
    end

    res
  end

  @doc """

  Makes sure `value` typechecks the type `type`. Evaluated _at runtime_.

  Because `dynamic_conforms/2` is evaluated at runtime:

  1. The typecheck cannot be optimized by the compiler, which makes it slower.

  2. You must pass an already-expanded type as `type`.
     This can be done by using one of your custom types directly (e.g. `YourModule.typename()`),
     or by calling `TypeCheck.Type.build`.

  Use `dynamic_conforms` only when you cannot use the normal `conforms/2`,
  for instance when you're only able to construct the type to check against at runtime.

      iex> fourty_two = TypeCheck.Type.build(42)
      iex> TypeCheck.dynamic_conforms(42, fourty_two)
      {:ok, 42}
      iex> {:error, type_error} = TypeCheck.dynamic_conforms(20, fourty_two)
      iex> type_error.message
      "At lib/type_check.ex:279:
          `20` is not the same value as `42`."
  """
  @spec dynamic_conforms(value, TypeCheck.Type.t()) ::
          {:ok, value} | {:error, TypeCheck.TypeError.t()}
  def dynamic_conforms(value, type, options \\ TypeCheck.Options.new()) do
    evaluated_options = TypeCheck.Options.new(options)
    check_code = TypeCheck.Protocols.ToCheck.to_check(type, Macro.var(:value, nil))

    if(evaluated_options.debug) do
      TypeCheck.Internals.Helper.prettyprint_spec("TypeCheck.dynamic_conforms(#{inspect(value)}, #{inspect(type)}, #{inspect(options)})", check_code)
    end

    case Code.eval_quoted(check_code, value: value) do
      {{:ok, _, altered_value}, _} -> {:ok, altered_value}
      {{:error, problem}, _} ->
        {:current_stacktrace, [_ , caller | _]} = Process.info(self(), :current_stacktrace)
        location = elem(caller, 3)
        location = update_in(location[:file], &to_string/1)
        {:error, TypeCheck.TypeError.exception({problem, location})}
    end
  end

  @doc """
  Similar to `dynamic_conforms/2`, but returns `true` if the value typechecked and `false` if it did not.

  The same features and restrictions apply to this function as to `dynamic_conforms/2`.


      iex> fourty_two = TypeCheck.Type.build(42)
      iex> TypeCheck.dynamic_conforms?(42, fourty_two)
      true
      iex> TypeCheck.dynamic_conforms?(20, fourty_two)
      false
  """
  @spec dynamic_conforms?(value, TypeCheck.Type.t()) :: boolean
  def dynamic_conforms?(value, type, options \\ TypeCheck.Options.new()) do
    case dynamic_conforms(value, type, options) do
      {:ok, _value} -> true
      _other -> false
    end
  end

  @doc """
  Similar to `dynamic_conforms/2`, but returns `value` if the value typechecked and raises TypeCheck.TypeError if it did not.

  The same features and restrictions apply to this function as to `dynamic_conforms/2`.

      iex> fourty_two = TypeCheck.Type.build(42)
      iex> TypeCheck.dynamic_conforms!(42, fourty_two)
      42
      iex> TypeCheck.dynamic_conforms!(20, fourty_two)
      ** (TypeCheck.TypeError) At lib/type_check.ex:279:
          `20` is not the same value as `42`.
  """
  @spec dynamic_conforms!(value, TypeCheck.Type.t()) :: value | no_return()
  def dynamic_conforms!(value, type, options \\ TypeCheck.Options.new()) do
    case dynamic_conforms(value, type, options) do
      {:ok, value} -> value
      {:error, exception} -> raise exception
    end
  end
end
