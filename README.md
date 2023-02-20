![](https://raw.githubusercontent.com/Qqwy/elixir-type_check/master/media/type_check_logo_flat.svg)

# TypeCheck: Fast and flexible runtime type-checking for your Elixir projects.

[![hex.pm version](https://img.shields.io/hexpm/v/type_check.svg)](https://hex.pm/packages/type_check)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/type_check/index.html)
[![ci](https://github.com/Qqwy/elixir-type_check/actions/workflows/ci.yml/badge.svg)](https://github.com/Qqwy/elixir-type_check/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/Qqwy/elixir-type_check/badge.svg)](https://coveralls.io/github/Qqwy/elixir-type_check)

## Core ideas

- Type- and function specifications are constructed using (essentially) the **same syntax** as built-in Elixir Typespecs.
- When a value does not match a type check, the user is shown **human-friendly error messages**.
- Types and type-checks are generated at compiletime.
  - This means **type-checking code is optimized** rigorously by the compiler.
- **Property-checking generators** can be extracted from type specifications without extra work.
  - Automatically create a **spectest** which checks for each function if it adheres to its spec.
- Flexibility to add **custom checks**: Subparts of a type can be named, and 'type guards' can be specified to restrict what values are allowed to match that refer to these types.


Prefer to watch a presentation instead of reading? See ["TypeCheck: Effortless Runtime Type Checking" - Marten Wijnja - _ElixirConf EU 2022_](https://www.youtube.com/watch?v=7ykfO2tBwYw).

## Usage Example

We add `use TypeCheck` to a module 
and wherever we want to add runtime type-checks 
we replace the normal calls to `@type` and `@spec` with `@type!` and `@spec!` respectively.

```elixir
defmodule User do
  use TypeCheck
  defstruct [:name, :age]

  @type! t :: %User{name: binary, age: integer}
end

defmodule AgeCheck do
  use TypeCheck

  @spec! user_older_than?(User.t, integer) :: boolean
  def user_older_than?(user, age) do
    user.age >= age
  end
end
```

Now we can try the following:

```elixir
iex> AgeCheck.user_older_than?(%User{name: "Qqwy", age: 11}, 10)
true
iex> AgeCheck.user_older_than?(%User{name: "Qqwy", age: 9}, 10)
false
```

So far so good. Now let's see what happens when we pass values that are incorrect:

```elixir
iex> AgeCheck.user_older_than?("foobar", 42)
** (TypeCheck.TypeError) At lib/type_check_example.ex:28:
The call to `user_older_than?/2` failed,
because parameter no. 1 does not adhere to the spec `%User{age: integer(), name: binary()}`.
Rather, its value is: `"foobar"`.
Details:
  The call `user_older_than?("foobar", 42)` 
  does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer()) :: boolean()`. Reason:
    parameter no. 1:
      `"foobar"` does not check against `%User{age: integer(), name: binary()}`. Reason:
        `"foobar"` is not a map.
    (type_check_example 0.1.0) lib/type_check_example.ex:28: AgeCheck.user_older_than?/2
```

```elixir
iex> AgeCheck.user_older_than?(%User{name: nil, age: 11}, 10)
** (TypeCheck.TypeError) At lib/type_check_example.ex:28:
The call to `user_older_than?/2` failed,
because parameter no. 1 does not adhere to the spec `%User{age: integer(), name: binary()}`.
Rather, its value is: `%User{age: 11, name: nil}`.
Details:
  The call `user_older_than?(%User{age: 11, name: nil}, 10)` 
  does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer()) :: boolean()`. Reason:
    parameter no. 1:
      `%User{age: 11, name: nil}` does not check against `%User{age: integer(), name: binary()}`. Reason:
        under key `:name`:
          `nil` is not a binary.
    (type_check_example 0.1.0) lib/type_check_example.ex:28: AgeCheck.user_older_than?/2
```

```elixir
iex> AgeCheck.user_older_than?(%User{name: "Aaron", age: nil}, 10) 
** (TypeCheck.TypeError) At lib/type_check_example.ex:28:
The call to `user_older_than?/2` failed,
because parameter no. 1 does not adhere to the spec `%User{age: integer(), name: binary()}`.
Rather, its value is: `%User{age: nil, name: "Aaron"}`.
Details:
  The call `user_older_than?(%User{age: nil, name: "Aaron"}, 10)` 
  does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer()) :: boolean()`. Reason:
    parameter no. 1:
      `%User{age: nil, name: "Aaron"}` does not check against `%User{age: integer(), name: binary()}`. Reason:
        under key `:age`:
          `nil` is not an integer.
    (type_check_example 0.1.0) lib/type_check_example.ex:28: AgeCheck.user_older_than?/2
```

```elixir
    
iex> AgeCheck.user_older_than?(%User{name: "José", age: 11}, 10.0) 
** (TypeCheck.TypeError) At lib/type_check_example.ex:28:
The call to `user_older_than?/2` failed,
because parameter no. 2 does not adhere to the spec `integer()`.
Rather, its value is: `10.0`.
Details:
  The call `user_older_than?(%User{age: 11, name: "José"}, 10.0)` 
  does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer()) :: boolean()`. Reason:
    parameter no. 2:
      `10.0` is not an integer.
    (type_check_example 0.1.0) lib/type_check_example.ex:28: AgeCheck.user_older_than?/2
```

And if we were to introduce an error in the function definition:

```elixir
defmodule AgeCheck do
  use TypeCheck

  @spec! user_older_than?(User.t, integer) :: boolean
  def user_older_than?(user, age) do
    user.age
  end
end
```

Then we get a nice error message explaining that problem as well:

```elixir
** (TypeCheck.TypeError) The call to `user_older_than?/2` failed,
because the returned result does not adhere to the spec `boolean()`.
Rather, its value is: `26`.
Details:
  The result of calling `user_older_than?(%User{age: 26, name: "Marten"}, 10)` 
  does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer()) :: boolean()`. Reason:
    Returned result:
      `26` is not a boolean.
    (type_check_example 0.1.0) lib/type_check_example.ex:28: AgeCheck.user_older_than?/2
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
  - [x] Bitstring type syntax (`<<>>`, `<<_ :: size>>`, `<<_ :: _ * unit>>`, `<<_ :: size, _ :: _ * unit>>`)
- [x] A `when` to add guards to typedefs for more power.
- [x] Make errors raised when types do not match humanly readable
  - [x] Improve readability of spec-errors by repeating spec and which parameter did not match.
- [x] Creating generators from types
- [x] Don't warn on zero-arity types used without parentheses.
- [x] Hide structure of `opaque` and `typep` from documentation
- [x] Make sure to handle recursive (and mutually recursive) types without hanging.
  - [x] A compile-error is raised when a type is expanded more than a million times
  - [x] A macro called `lazy` is introduced to allow to defer type expansion to runtime (to _within_ the check).
- [x] the Elixir formatter likes the way types+specs are constructed
- [x] A type `impl(ProtocolName)` to work with 'any type implementing protocol `Protocolname`'.
  - [x] Type checks.
  - [x] StreamData generator.
- [x] High code-coverage to ensure stability of implementation.
- [x] Make sure we handle most (if not all) of Typespec's primitive types and syntax. (With the exception of functions and binary pattern matching)
- [x] Option to turn `@type/@opaque/@typep`-injection off for the cases in which it generates improper results.
- [x] Manually overriding generators for user-specified types if so desired.
- [x] Creating generators from specs
  - [x] Wrap spec-generators so you have a single statement to call in the test suite which will prop-test your function against all allowed inputs/outputs.
- [x] Option to turn the generation of runtime checks off for a given module in a particular environment (`enable_runtime_checks`).
- [x] Support for function-types (for typechecks as well as property-testing generators):
  - `(-> result_type)`
  - `(...-> result_type)`
  - `(param_type, param2_type -> result_type)`
- [x] Basic support for maps with a single `required(type)` or `optional(type)`.
- [x] Overrides for builtin remote types (`String.t`,`Enum.t`, `Range.t`, `MapSet.t` etc.) **(75% done)** [Details](https://hexdocs.pm/type_check/comparing-typecheck-and-elixir-typespecs.html#elixir-standard-library-types)
- [x] Overrides for more builtin remote types
- [x] Support for maps with mixed `required(type)` and `optional(type)` syntaxes.
- [x] Configurable setting to turn checks on/off at compile-time, on a per-OTP-app basis (so you have control over your dependencies) as well as your individual modules.
- [x] Hide named types from opaque types.
- [x] A way to define structs and their field types at the same time.
- [x] Finalize formatter specification and make a generator for this so that people can easily test their own formatters.

### Pre-stable


### Longer-term future ideas

- [ ] Per-module or even per-spec settings to turn on/off, configure formatter, etc.


## Installation

TypeCheck [is available in Hex](https://hex.pm/docs/publish). The package can be installed
by adding `type_check` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:type_check, "~> 0.13.3"},
    # To allow spectesting and property-testing data generators (optional):
    {:stream_data, "~> 0.5.0", only: :test}, 
  ]
end
```

The documentation can be found at [https://hexdocs.pm/type_check](https://hexdocs.pm/type_check).


### Formatter

TypeCheck exports a couple of macros that you might want to use without parentheses. To make `mix format` respect this setting, add `import_deps: [:type_check]` to your `.formatter.exs` file.

## Changelog

The full changelog can be found [here](https://github.com/Qqwy/elixir-type_check/blob/main/CHANGELOG.md)

## TypeCheck compared to other tools

TypeCheck is by no means the other solution out there to reduce the number of bugs in your code.

### Elixir's builtin typespecs and Dialyzer

[Elixir's builtin type-specifications](https://hexdocs.pm/elixir/typespecs.html) use the same syntax as TypeCheck.
They are however not used by the compiler or the runtime, and therefore mainly exist to improve your documentation.

Besides documentation, extra external tools like [Dialyzer](http://erlang.org/doc/apps/dialyzer/dialyzer_chapter.html) can be used to perform static analysis of the types used in your application.

Dialyzer is an opt-in static analysis tool. This means that it can point out some inconsistencies or bugs, but because of its opt-in nature, there are also many problems it cannot detect, and it requires your dependencies to have written all of their typespecs correctly.

Dialyzer is also (unfortunately) infamous for its at times difficult-to-understand error messages.

An advantage that Dialyzer has over TypeCheck is that its checking is done without having to execute your program code (thus not having any effect on the runtime behaviour or efficiency of your projects).

Because TypeCheck adds `@type`, `@typep`, `@opaque` and `@spec`-attributes based on the types that are defined, it is possible to use Dialyzer together with TypeCheck.

### Norm

[Norm](https://github.com/keathley/norm/) is an Elixir library for specifying the structure of data that can be used for both validation and data-generation.

On a superficial level, Norm and TypeCheck seem similar. However, there are [important differences in their design considerations](https://github.com/Qqwy/elixir-type_check/blob/master/Comparing%20TypeCheck%20and%20Norm.md).


## Is it any good?

[yes](https://news.ycombinator.com/item?id=3067434)
