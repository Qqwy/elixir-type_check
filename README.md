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

  type t :: %User{name: binary, age: integer}
end

defmodule AgeCheck do
  use TypeCheck

  spec user_older_than?(User.t, integer) :: boolean
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
** (TypeCheck.TypeError) The call `user_older_than?("foobar", 42)` does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer())
::
boolean()`. Reason:
  parameter no. 1:
    `"foobar"` does not check against `%User{age: integer(), name: binary()}`. Reason:
      `"foobar"` is not a map.

iex> AgeCheck.user_older_than?(%User{name: nil, age: 11}, 10)
** (TypeCheck.TypeError) The call `user_older_than?(%User{age: 11, name: nil}, 10)` does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer())
::
boolean()`. Reason:
  parameter no. 1:
    `%User{age: nil, name: nil}` does not check against `%User{age: integer(), name: binary()}`. Reason:
      under key `:name`:
        `nil` is not a binary.

iex> AgeCheck.user_older_than?(%User{name: "Aaron", age: nil}, 10) 
** (TypeCheck.TypeError) The call `user_older_than?(%User{age: nil, name: "Aaron"}, 10)` does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer())
::
boolean()`. Reason:
  parameter no. 1:
    `%User{age: nil, name: "Aaron"}` does not check against `%User{age: integer(), name: binary()}`. Reason:
      under key `:age`:
        `nil` is not an integer.

iex> AgeCheck.user_older_than?(%User{name: "José", age: 11}, 10.0) 
** (TypeCheck.TypeError) The call `user_older_than?(%User{age: 11, name: "José"}, 10.0)` does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer())
::
boolean()`. Reason:
  parameter no. 2:
    `10.0` is not an integer.
```

And if we were to introduce an error in the function definition:

```elixir
defmodule AgeCheck do
  use TypeCheck

  spec user_older_than?(User.t, integer) :: boolean
  def user_older_than?(user, age) do
    user.age
  end
end
```

Then we get a nice error message explaining that problem as well:

```elixir
** (TypeCheck.TypeError) The result of calling `user_older_than?(%User{age: 26, name: "Marten"}, 10)` does not adhere to spec `user_older_than?(%User{age: integer(), name: binary()},  integer())
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

On a superficial level, Norm and TypeCheck seem similar. However, there are [important differences in their design considerations](Comparing TypeCheck and Norm.md).

## Changelog

- 0.1.2 Adding the `keyword()` and `keyword(t)` builtin types that were still missing.
- 0.1.1 Fixing some typographic errors in the documentation.
- 0.1.0 Initial Release

## Is it any good?

[yes](https://news.ycombinator.com/item?id=3067434)
