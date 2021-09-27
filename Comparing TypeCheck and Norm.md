### Norm

[Norm](https://github.com/keathley/norm/) is an Elixir library for specifying the structure of data that can be used for both validation and data-generation.

On a superficial level, Norm and TypeCheck seem similar. However, there are important differences in their design considerations:

#### Primary Focus 

Norm focuses on conforming values to specifications by re-using your existing validations. 
Norm also has a focus on 'open' schemas that are designed to allow systems to grow over time.

TypeCheck focuses on making the types your program is using explicit. 
This is done by retrofitting Elixir's built-in type syntax to allow you to use a single statement to create 
1. an expanded type-/function-specification for in the documentation, 
2. runtime type-checking code and
3. data-generation for property-testing.

#### Syntax

Norm uses a new, guard-like function-call syntax.
Norm is light on the little syntactic sugar: Literal atoms and tuples containing specs as elements are treated as specs themselves. 
Anything else requires you to write a (dedicated or anonymous) validation function.

TypeCheck uses the same syntax that Elixir's built-in typespecs use, which is already familiar to many Elixir developers.
This makes a TypeCheck `@type!` or `@spec!` often much shorter than the equivalent Norm `spec` or `@contract`.

##### A couple of syntactical examples:

A simple 'manual' validation. (This is common Norm usage but manual validations are more rare in TypeCheck.)

```elixir
# Norm:
iex> Norm.conform!(123, spec(is_integer() and &(&1 > 0)))
123
```

```elixir
# TypeCheck
iex> TypeCheck.conforms!(123, non_neg_integer())
# or:
iex> TypeCheck.conforms!(123, x :: integer() when x >= 0)
```

Defining custom type-specifications ('specs' in Norm parlance) and function-specifications ('contracts' in Norm parlance):

```elixir
# Norm:
defmodule Color do
  import Norm
  def rgb(), do: spec(is_integer() and &(&1 in 0..255))
  def hex(), do: spec(is_binary() and &String.starts_with?(&1, "#"))
  
  @contract rgb_to_hex(r :: rgb(), g :: rgb(), b :: rgb()) :: hex()
  def rgb_to_hex(r, g, b) do
    # ...
  end
end
```

```elixir
# TypeCheck:
defmodule Color do
  use TypeCheck
  @type! rgb :: 0..255
  @type! hex :: (str :: binary() when String.starts_with?(str, "#"))
  
  @spec! rgb_to_hex(rgb, rgb, rgb) :: hex
  def rgb_to_hex(r, g, b) do
    # ...
  end
end
```

Defining a more complicated specification of a custom structure with multiple fields:

```elixir
# Norm:
defmodule User do
  use Norm

  defstruct [:name, :age]
  def age_spec(), do: spec(is_integer() and &(&1 >= 0))
  def s() do
    schema(%{
      name: spec(is_binary()),
      age: age_spec(),
    })
  end
  
  @contract new(name :: spec(is_binary()), age :: age_spec()) :: s()
  def new(name, age) do
    %__MODULE__{name: name, age: age}
  end
  
  @contract ensure_old_enough(user :: s(), limit :: age_spec()) :: alt(success: {:ok, s()}, problem: {:error, spec(is_binary())})
  def ensure_old_enough(user, limit) do
    if user.age >= limit do
      {:ok, user}
    else
      {:error, "not old enough"}
    end
  end
end
```

```elixir
# TypeCheck:
defmodule User do
  use TypeCheck
  defstruct [:name, :age]
  @type! age :: non_neg_integer()
  @type! t :: %User{name: binary(), age: age()}

  @spec! new(binary(), age()) :: t()
  def new(name, age) do
    %User{name: name, age: age}
  end

  @spec! ensure_old_enough(t(), age()) :: {:ok, t()} | {:error, binary()}
  def ensure_old_enough(user, limit) do
    if user.age >= limit do
      {:ok, user}
    else
      {:error, "not old enough"}
    end
  end
end
```

#### Execution

In Norm, while wrapping functions with a contract happens at compile-time, 
all contracts and specs are resolved at runtime.
This makes Norm's internals less metaprogramming-heavy and easily allows specs to be created and manipulated dynamically at runtime, 
but it does mean that the compiler is not able to optimize the type-checking code at all, and specs are re-evaluated every time a function is called.

TypeCheck requires¹ types to be defined at compile-time and injects the type-checking code to your functions and modules before they are compiled, 
allowing type-checking to be optimized.
If there is overlap between the parts of your parameters being checked by TypeCheck and the logic of your function,
the BEAM compiler will in most cases be able to combine these into a single check.

¹: In normal usage. Escape hatches to work with types defined at runtime exist.

#### Documentation

Norm does not focus on dcumentation.
Norm's `spec`s are normal functions which you can document manually using `@doc` if you wish. 
Norm's `@contract`s are not used for documentation purposes.

TypeCheck adds `@type`/`@typep`/`@opaque` attributes for the types you specify, making them show up in your documentation 
and allowing you to use the same type definitions for tools like `Dialyzer`. 
You can also use the `t` helper to look them up in IEx. 
Documentation can be added to these types by using `@typedoc` (just like for normal typespecs).

Function-specifications created with TypeCheck will also add `@spec`-attributes, which will end up in the documentation of your functions and are similarly useful for e.g. `Dialyzer`.

#### Data Generation

It is very useful to generate examples of good data to be used for property testing.
Both Norm and TypeCheck have this capability, by using `:stream_data` as an optional dependency.

Norm's generators (only) work when the first predicate in a `spec(...)` is one of (a subset of) Elixir's built-in guard-clauses. 
If your spec is too restrictive, you'll have to manually provide a custom data generator as well.

TypeCheck builds more complicated generators out of simple ones just as it builds complicated types out of simple ones. 
This means that virtually all Elixir types can be turned into generators without extra effort of the user. 
It is only when 'type guards' are used to add arbitrary checks to a type that you might up with a generator that is too restrictive. 
TypeCheck supports nearly all of Elixir's builtin types, as well as many of the remote types that are part of Elixir's standard library (`Range.t`, `MapSet.t`, `List.t`, `Enum.t` etc.)

Furthermore, TypeCheck allows overriding the generator for a type (c.f. the `TypeCheck.Type.StreamData.wrap_with_gen/2` macro).

Finally and maybe most importantly, TypeCheck ships with the `spectest` macro 
which will automatically run a property-test to check for each `@spec!`-ced function in a module, whether it correctly follows its spec.

#### Error messages

Norm does not particulary focus on readable error messages (although that might change in the future).

TypeCheck heavily focuses on creating humanly-readable error-messages when a value does not type-check,
creating a deeply nested error message indicating the cause of a top-level error (see the main README for some examples of this). 
TypeCheck's error messages are based on a pluggable formatter for which custom alternatives can be provided.

As an example, consider the execution using the respective definitions of `User.ensure_old_enough` above:

```elixir
User.ensure_old_enough(%User{name: "Marten", age: 0.5}, 21)
** (Norm.MismatchError) Could not conform input:
val: 0.5 in: :age fails: is_integer()
    (norm 0.13.0) lib/norm.ex:65: Norm.conform!/2
    (norm_example 0.1.0) lib/norm_example.ex:38: anonymous fn/2 in User.ensure_old_enough/2
    (elixir 1.12.0) lib/enum.ex:2356: Enum."-reduce/3-lists^foldl/2-0-"/3
    (norm_example 0.1.0) lib/norm_example.ex:38: User.ensure_old_enough/2
```

```elixir
** (TypeCheck.TypeError) At lib/type_check_example.ex:21:
The call to `ensure_old_enough/2` failed,
because parameter no. 1 does not adhere to the spec `%User{age: non_neg_integer(), name: binary()}`.
Rather, its value is: `%User{age: 0.5, name: "Marten"}`.
Details:
  The call `ensure_old_enough(%User{age: 0.5, name: "Marten"}, 21)`
  does not adhere to spec `ensure_old_enough(%User{age: non_neg_integer(), name: binary()}, non_neg_integer())
::
{:ok, %User{age: non_neg_integer(), name: binary()}} | {:error, binary()}`. Reason:
    parameter no. 1:
      `%User{age: 0.5, name: "Marten"}` does not check against `%User{age: non_neg_integer(), name: binary()}`. Reason:
        under key `:age`:
          `0.5` is not a non-negative integer.
    (type_check_example 0.1.0) lib/type_check/spec.ex:165: User.ensure_old_enough/2

```

---

Norm and TypeCheck are but two different dots in the datastructure-validation design space. Norm is definitely worth checking out!
