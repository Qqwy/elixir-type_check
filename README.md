![](https://raw.githubusercontent.com/Qqwy/elixir-type_check/master/media/type_check_logo_flat.svg)

# TypeCheck: Fast and flexible runtime type-checking for your Elixir projects.


[![hex.pm version](https://img.shields.io/hexpm/v/type_check.svg)](https://hex.pm/packages/type_check)
[![Build Status](https://travis-ci.org/Qqwy/elixir-type_check.svg?branch=master)](https://travis-ci.org/Qqwy/elixir-type_check)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/type_check/index.html)

## Core ideas

- Type- and function specifications are constructed using (essentially) the **same syntax** as built-in Elixir Typespecs.
- When a value does not match a type check, the user is shown **human-friendly error messages**.
- Types and type-checks are generated at compiletime.
  - This means **type-checking code is optimized** rigorously by the compiler.
- **Property-checking generators** can be extracted from type specifications without extra work.
- Flexibility to add **custom checks**: Subparts of a type can be named, and 'type guards' can be specified to restrict what values are allowed to match that refer to these types.


## Usage Example

```elixir
defmodule User do
  use TypeCheck
  defstruct [:name, :age]

  type t :: %__MODULE__{name: binary, age: integer}
end

defmodule AgeCheck do
  use TypeCheck

  spec is_user_older_than?(User.t, integer) :: boolean
  def is_user_older_than?(user, age) do
    user.age >= age
  end
end
```

Now we can try the following:

```elixir
iex> AgeCheck.is_user_older_than?(%User{name: "Qqwy", age: 11}, 10)
true
iex> AgeCheck.is_user_older_than?(%User{name: "Qqwy", age: 9}, 10)
false
```

So far so good. Now let's see what happens when we pass values that are incorrect:

```elixir
iex> AgeCheck.is_user_older_than?("foobar", 42)
** (TypeCheck.TypeError) The call `is_user_older_than?("foobar", 42)` does not adhere to spec `is_user_older_than?(%User{age: integer(), name: binary()},  integer())
::
boolean()`. Reason:
  parameter no. 1:
    `"foobar"` does not check against `%User{age: integer(), name: binary()}`. Reason:
      `"foobar"` is not a map.

iex> AgeCheck.is_user_older_than?(%User{name: nil, age: 11}, 10)
** (TypeCheck.TypeError) The call `is_user_older_than?(%Example3.User{age: 11, name: nil}, 10)` does not adhere to spec `is_user_older_than?(%User{age: integer(), name: binary()},  integer())
::
boolean()`. Reason:
  parameter no. 1:
    `%Example3.User{age: nil, name: nil}` does not check against `%User{age: integer(), name: binary()}`. Reason:
      under key `:name`:
        `nil` is not a binary.

iex> AgeCheck.is_user_older_than?(%User{name: "Aaron", age: nil}, 10) 
** (TypeCheck.TypeError) The call `is_user_older_than?(%User{age: nil, name: "Aaron"}, 10)` does not adhere to spec `is_user_older_than?(%User{age: integer(), name: binary()},  integer())
::
boolean()`. Reason:
  parameter no. 1:
    `%Example3.User{age: nil, name: "Aaron"}` does not check against `%User{age: integer(), name: binary()}`. Reason:
      under key `:age`:
        `nil` is not an integer.

iex> AgeCheck.is_user_older_than?(%User{name: "José", age: 11}, 10.0) 
** (TypeCheck.TypeError) The call `is_user_older_than?(%User{age: 11, name: "José"}, 10.0)` does not adhere to spec `is_user_older_than?(%User{age: integer(), name: binary()},  integer())
::
boolean()`. Reason:
  parameter no. 2:
    `10.0` is not an integer.
```

And if we were to introduce an error in the function definition:

```elixir
defmodule AgeCheck do
  use TypeCheck

  spec is_user_older_than?(User.t, integer) :: boolean
  def is_user_older_than?(user, age) do
    user.age
  end
end
```

Then we get a nice error message explaining that problem as well:

```elixir
** (TypeCheck.TypeError) The result of calling `is_user_older_than?(%User{age: 26, name: "Marten"}, 10)` does not adhere to spec `is_user_older_than?(%User{age: integer(), name: binary()},  integer())
::
boolean()`. Reason:
  Returned result:
    `2` is not a boolean.
```

## Features & Roadmap


### Implemented

- [x] Proof and implementation of the basic concept
- [x] Custom type definitions (type, typep, opaque)
  - [x] Basic
  - [x] Parameterized
- [x] Hide implementation of `opaque` from documentation
- [x] Spec argument types checking
- [x] Spec return type checking
- [x] Spec possibly named arguments
- [x] Implementation of Elixir's builtin types
  - [x] Primitive types
  - [x] More primitive types
  - [x] Compound types
  - [x] special forms like `|`, `a..b` etc.
  - [x] Literal lists
  - [x] Maps with keys => types
  - [x] Structs with keys => types
  - [x] More map/list-based structures.
- [x] A `when` to add guards to typedefs for more power.
- [x] Make errors raised when types do not match humanly readable
  - [x] Improve readability of spec-errors by repeating spec and which parameter did not match.
- [x] Creating generators from types
- [x] Don't warn on zero-arity types used without parentheses.
- [x] Hide structure of `opaque` and `typep` from documentation
- [x] Make sure to handle recursive (and mutually recursive) types without hanging.
  - [x] A compile-error is raised when a type is expanded more than a million times
  - [x] A macro called `lazy` is introduced to allow to defer type expansion to runtime (to _within_ the check).


### Pre-stable

- [ ] Hide named types from opaque types.
- [ ] Make sure we handle most (if not all) of Typespec's primitive types and syntax.
- [ ] Overrides for builtin remote types (`String.t`,`Enum.t`, `Range.t`, `MapSet.t` etc.)
- [ ] Option to turn `@type/@opaque/@typep`-injection off for the cases in which it generates improper results.
- [ ] Configurable setting to turn on/off at compile-time, and maybe dynamically at run-time (with slight performance penalty).
- [ ] Finalize formatter specification and make a generator for this so that people can easily test their own formatters.
- [ ] Manually overriding generators for user-specified types if so desired.

### Longer-term future ideas

- [ ] Creating generators from specs
  - [ ] Wrap spec-generators so you have a single statement to call in the test suite which will prop-test your function against all allowed inputs/outputs.
- [ ] Per-module or even per-spec settings to turn on/off, configure formatter, etc.

## Installation

TypeCheck [is available in Hex](https://hex.pm/docs/publish). The package can be installed
by adding `type_check` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:type_check, "~> 0.1.0"}
  ]
end
```

The documentation can be found at [https://hexdocs.pm/type_check](https://hexdocs.pm/type_check).

### Formatter

TypeCheck exports a couple of macros that you might want to use without parentheses. To make `mix format` respect this setting, add `import_deps: [:type_check]` to your `.formatter.exs` file.

## Comparing TypeCheck with other tools

### Elixir's builtin typespecs and Dialyzer

[Elixir's builtin type-specifications](https://hexdocs.pm/elixir/typespecs.html) use the same syntax as TypeCheck.
They are however not used by the compiler or the runtime, and therefore mainly exist to improve your documentation.

On top of providing documentation, [Dialyzer](http://erlang.org/doc/apps/dialyzer/dialyzer_chapter.html) can be used to perform static analysis of the types used in your application.

Dialyzer is an opt-in static analysis tool. This means that it can point out some inconsistencies or bugs, but because of its opt-in nature, there are also many problems it cannot detect, and it requires your dependencies to have written all of their typespecs correctly.

Dialyzer is also (unfortunately) infamous for its at times difficult-to-understand error messages.

An advantage that Dialyzer has over TypeCheck is that its checking is done without having to execute your program code (thus not having any effect on the runtime behaviour or efficiency of your projects).

Because TypeCheck injects `@type`, `@typep`, `@opaque` and `@spec`-attributes based on the types that are defined, it is possible to use Dialyzer together with TypeCheck. This might be worthwhile, because Dialyzer can point out .

### Norm

[Norm](https://github.com/keathley/norm/) is an Elixir library for specifying the structure of data that can be used for both validation and data-generation.

On a superficial level, Norm and TypeCheck seem similar. However, there are important differences in the way they operate:

#### Primary Focus 

Norm focuses on conforming values to specifications by re-using your existing validations. Norm also has a focus on 'open' schemas that are designed to allow systems to grow over time.

TypeCheck focuses on making the types your program is using explicit. This is done by retrofitting Elixir's built-in type syntax to allow you to use a single statement to create (i) a type-/function-specification for in the documentation, (ii) runtime type-checking code and (iii) data-generation for property-testing.

#### Syntax

Norm uses a new, guard-like function-call syntax.
Norm is light on the little syntactic sugar: Literal atoms and tuples containing specs as elements are treated as specs themselves. Anything else requires you to write a (dedicated or anonymous) validation function.

TypeCheck uses the same syntax that Elixir's built-in typespecs use (and is heavy on the syntactic sugar to make this possible).

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
  type rgb :: 0..255
  type hex :: (str :: binary() when String.starts_with?(str, "#"))
  
  spec rgb_to_hex(rgb, rgb, rgb) :: hex
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
# TypeCheck
defmodule User do
  use TypeCheck
  defstruct [:name, :age]
  type age :: non_neg_integer()
  type t :: %User{name: binary(), age: age()}

  spec new(binary, age) :: t
  def new(name, age) do
    %User{name: name, age: age}
  end

  spec ensure_old_enough(t, age) :: {:ok, t} | {:error, binary}
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

While wrapping functions with a contract happens at compile-time, all contracts and specs are resolved at runtime.
This makes Norm's internals less metaprogramming-heavy and allows specs to be created dynamically at runtime, but it does mean that the compiler is not able to optimize the type-checking code.

TypeCheck requires (assuming normal usage; escape hatches exist) types to be defined at compile-time and injects the type-checking code to your functions and modules before they are compiled, allowing type-checking to be optimized.

#### Documentation

Norm does not focus on dcumentation.
Norm's `spec`s are normal functions which you can document manually using `@doc` if you wish. Norm's `@contract`s are not used for documentation purposes.

TypeCheck adds `@type`/`@typep`/`@opaque` attributes for the types you specify, making them show up in your documentation and allowing you to use the same type definitions for tools like `Dialyzer`. You can also use the `t` helper to look them up in IEx. Documentation can be added to these types by using `@typedoc`.
Function-specifications created with TypeCheck will also add `@spec`-attributes, which will end up in the documentation of your functions and are similarly useful for e.g. `Dialyzer`.

#### Data Generation

It is very useful to generate examples of good data to be used for property testing.
Both Norm and TypeCheck have this capability, by using `:stream_data` as an optional dependency.

Norm's generators (only) work when the first predicate in a `spec(...)` is one of Elixir's built-in guard-clauses. If your spec is too restrictive, you'll have to manually provide a custom data generator as well.

TypeCheck builds more complicated generators out of simple ones just as it builds complicated types out of simple ones. This means that virtually all Elixir types can be turned into generators without extra effort of the user. It is only when 'type guards' are used to add arbitrary checks to a type that you might up with a generator that is too restrictive. _Currently TypeCheck has no built-in way to customize the generator function, but this is one of the features we'd like to add before a stable release._

#### Error messages

TypeCheck heavily focuses on creating humanly-readable error-messages when a value does not type-check. Norm does not particulary focus on this, (although that might change in the future).


## Is it any good?

[yes](https://news.ycombinator.com/item?id=3067434)
