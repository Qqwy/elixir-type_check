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

### Changelog
- 0.13.0 - 
  - Additions:
    - Support for maps with multiple optional atom keys. Thank you very much, @dvic! (c.f. #165)
- 0.12.4 - 
  - Fixes:
    - Allow syntax `%{String.t() => any()}` as shorthand for `%{required(String.t()) => any()}`. (c.f. #152)
    - Situations in which the fully qualified name of a type defined in the current module were not picked up (`Example.t()` not being found inside specs in `Example`. even though `Example` defined a type called `t()`). (c.f. #154)
    - A problem with using types with type guards in other modules. (c.f. #147)
- 0.12.3 -
  - Fixes:
    - Compatibility problems with Elixir v1.14. (`Code.Identifier.inspect_as_key`, working with the AST of imported functions)  Thank you very much, @marcandre! (c.f. #150)
- 0.12.2 -
  - Fixes:
    - Compilation error in a new Phoenix 1.16 project. Thank you very much, @assimelha! (c.f. #114)
- 0.12.1 - 
  - Performance:
    - Significant reduction on generated code size of runtime type checks. This will speed up compilation roughly ~10-50%.
  - Fixes:
    - No longer use white ANSI color in exception formatting, ensuring messages of the DefaultFormatter are also visible on white backgrounds (Livebook, anyone? :D)
    - Skip OTP app lookup (used to fetch per OTP app compile-time configuration) if we're not compiled inside an OTP app (such as inside a Livebook).
    - Improve generator for `Regex.t()` to generate only correct regular expressions. Thank you very much, @skwerlman!(c.f. #133)
- 0.12.0 - 
  - Additions:
    - The default options used are now fetched from the application configuration. This means that you can configure a default for your app as well as for each of your dependencies(!) by adding `config :app_name, :type_check [...]` to your configuration file(s). (c.f. #61)
    - `TypeCheck.External` module, with functions to work with typespecs in modules outside of your control. Thank you very much, @orsinium! (c.f. #113)
      - `fetch_spec` to build a TypeCheck type from any function that has a `@spec`.
      - `fetch_type` to build a TypeCheck type from any `@type`.
      - `enforce_spec!` to wrap a call to any function that has a `@spec` with a runtime type-check on the input parameters and return value.
      - `apply` and `apply!` to wrap a call to any function with the function spec type that you give it.
    - `TypeCheck.Defstruct.defstruct!`, a way to combine `defstruct`, `@enforce_keys` and the creation of the struct's type, reducing boilerplate and the possibility of mistakes. (c.f. #118)
  - Fixes:
    - Long-standing issue where Dialyzer would sometimes complain in apps using TypeCheck is resolved. (c.f. #95)
    - Creation of the new `maybe_nonempty_list` type will no longer get stuck in an infinite loop on creation. (c.f. #120)
- 0.11.0 - 
  - Additions:
    - Support for fancier map syntaxes:
      - `%{required(key_type) => value_type}` Maps with a single kind of required key-value type.
      - `%{optional(key_type) => value_type}` Maps with a single kind of optional key-value type.
      - `%{:some => a(), :fixed => b(), :keys => c(), optional(atom()) => any()}` Maps with any number of fixed keys and a single optional key-value type.
      - TypeCheck now supports nearly all kinds of map types that see use. Archaic combinations of optional and required are not supported, but also not very useful types in practice.
      - Because of this, the inspection of the builtin type `map(key, value)` has been changed to look the same as an optional map. _This is a minor backwards-incompatible change._
    - Desugaring `%{}` has changed from 'any map' to 'the empty map' in line with Elixir's Typespecs. _This is a minor backwards-incompatible change._
    - Support for the builtin types `port()`, `reference()` and (based on these) `identifier()`.
    - Support for the builtin type `struct()`.
    - Support for the builtin type `timeout()`.
    - Support for the builtin type `nonempty_charlist()` and `maybe_improper_list` and (based on these) `iolist()` and `iodata()`.
    - Adding types depending on these builtins to the default type overrides. **We now support all modules of the full standard library!**
    - `TypeCheck.Credo.Check.Readability.Specs`: an opt-in alternative Credo check which will check whether all functions have either a `@spec!` or 'normal' `@spec`. (Fixes #102).
- 0.10.8 - 
  - Fixes:
    - Ensures that the `Inspect` protocol is properly implemented for sized bitstring types (c.f. #104). Thank you very much, @trarbr!
- 0.10.7 - 
  - Fixes:
    - Ensures fixed-maps are checked for superfluous keys (c.f. #96). Thank you very much, @spatrik!
- 0.10.6 - 
  - Fixes:
    - Fixes issue where Dialyzer would sometimes complain about the generated return-type checking code if the implementation of the function itself was trivial. (c.f. #85).
- 0.10.5 - 
  - Additions:
    - Support for the builtin types of the `System` module. Thank you, @paulswartz!
- 0.10.4 -
  - Fixes:
    - Fixes issue where sometimes results of specs returning a struct would remove some or all struct fields. (c.f. #78)
    - Related: Ensures that when a `@type!` containing a `%__MODULE__{}` is used before that module's `defstruct`, a clear CompileError is created (c.f. #83).
- 0.10.3 - 
  - Fixes:
    - Fixes issue when TypeCheck specs were used inside a defprotocol module or other modules where the normal `def`/`defp` macros are hidden/overridden.
- 0.10.2 - 
  - Fixes:
    - Fixes issue where FixedMaps would accept maps any maps (even those missing the required keys) sometimes. (c.f. #74)
- 0.10.1 - 
  - Fixes:
    - Swaps `Murmur` out for Erlang's builtin `:erlang.phash2/2` to generate data for function-types, allowing the removal of the optional dependency on the `:murmur` library.
- 0.10.0 -
  - Additions
    - Support for function-types (for typechecks as well as property-testing generators):
      - `(-> result_type)`
      - `(...-> result_type)`
      - `(param_type, param2_type -> result_type)`
  - Fixes:
    - Wrapping private functions no longer make the function public. (c.f. #64)
    - Wrapping macros now works correctly. (also related to #64)
    - Using `__MODULE__` inside a struct inside a type now expands correctly. (c.f. #66)
- 0.9.0 - 
  - Support for bitstring type syntax: `<<>>`, `<<_ :: size>>`, `<<_ :: _ * unit>>`, `<<_ :: size, _ :: _ * unit>>` (both as types and as generators)
- 0.8.2 - 
  - Fixed compiler warnings when optional dependency StreamData is not installed.
  - Fixed pretty-printing of typedoc of opaque types.
- 0.8.1 - 
  - Improved documentation with a page comparing TypeCheck with Elixir's plain typespecs. (Thank you very much, @baldwindavid )
  - Addition of missing override for the type `t Range.t/0`. (Thank you very much, @baldwindavid )
- 0.8.0 -
  - Fixes prettyprinting of `TypeCheck.Builtin.Range`.
  - Addition of `require TypeCheck.Type` to `use TypeCheck` so there no longer is a need to call this manually if you want to e.g. use `TypeCheck.Type.build/1`.
  - Pretty-printing of types and TypeError output in multiple colors.
  - Nicer indentation of errors.
  - named types are now printed in abbreviated fashion if they are repeated multiple times in an error message. This makes a nested error message much easier to read, especially for larger specs.
  - `[type]` no longer creates a `fixed_list(type)` but instead a `list(type)` (just as Elixir's own typespecs.)
  - Support for `[...]` and `[type, ...]`as alias for `nonempty_list()` and `nonempty_list(type)` respectively.
  - Remove support for list literals with multiple elements.
  - Improved documentation. Thank you, @0ourobor0s!
- 0.7.0 - Addition of the option `enable_runtime_checks`. When false, all runtime checks in the given module are completely disabled.
  - Adding `DateTime.t` to the default overrides, as it was still missing.
- 0.6.0 - Addition of `spectest` & 'default overrides' Elixir's standard library types:
  - Adding `TypeCheck.ExUnit`, with the function `spectest` to test function-specifications.
    - Possibility to use options `:except`, `:only`, `:initial_seed`.
    - Possibility to pass custom options to StreamData.
  - Adding `TypeCheck.DefaultOverrides` with many sub-modules containing checked typespecs for the types in Elixir's standard library (75% done).
    - Ensure that these types are correct also on older Elixir versions (1.9, 1.10, 1.11)
  - By default load these 'DefaultOverrides', but have the option to turn this behaviour off in `TypeCheck.Option`. 
  - Nice generators for `Enum.t`, `Collectable.t`, `String.t`.
  - Support for the builtin types:
    - `pid()`
    - `nonempty_list()`, `nonempty_list(type)`.
  - Allow `use TypeCheck` in IEx or other non-module contexts, to require `TypeCheck` and import `TypeCheck.Builtin` in the current scope (without importing/using the macros that only work at the module level.)
  - The introspection function `__type_check__/1` is now added to any module that contains a `use TypeCheck`.
  - Fixes the `Inspect` implementation of custom structs, by falling back to `Any`, which is more useful than attempting to use a customized implementation that would try to read the values in the struct and failing because the struct-type containing types in the fields.
  - Fixes conditional compilation warnings when optional dependency `:stream_data` was not included in your project.
- 0.5.0 - Stability improvements:
  - Adding `Typecheck.Option` `debug: true`, which will (at compile-time) print the checks that TypeCheck is generating.
  - Actually autogenerate a `@spec`, which did not yet happen before.
  - When writing `@autogen_typespec false`, no typespec is exported for the next `@type!`/`@opaque`/`@spec!` encountered in a module.
  - Code coverage increased to 85%
  - Bugfixes w.r.t. generating typespecs
  - Fixes compiler-warnings on unused named types when using a type guard. (c.f. #25)
  - Fixes any warnings that were triggered during the test suite before.
- 0.4.0 - Support for `impl(ProtocolName)` to accept any type implementing a particular protocol.
  - Also adds rudimentary support for overriding remote types.
  - Bugfix when inspecting `lazy( ...)`-types.
- 0.3.2 - Support for unquote fragments inside types and specs. (c.f. #39)
- 0.3.1 - Fixed link in the documentation.
- 0.3.0 - Improve DefaultFormatter output when used with long function- or type-signatures (c.f. #32). Also, bugfix for `Builtin.tuple/1`.
- 0.2.3 - Bugfix release: Ensure TypeCheck compiles on Elixir v1.11 (#30), Ensure StreamData truly is an optional dependency (#27).
- 0.2.2 - Support for literal strings should no longer break in Elixir's builtin typespecs.
- 0.2.1 - Improved parsing of types that have a type-guard at the root level. (c.f. #24), support for custom generators.
- 0.2.0 - Improved (and changed) API that works better with the Elixir formatter: Use `@type!`/`@spec!` instead, support named types in specs.
- 0.1.2 - Added missing `keyword` type to TypeCheck.Builtin (#20)
- 0.1.1 - Fixing some documentation typos
- 0.1.0 - Initial Release

## Installation

TypeCheck [is available in Hex](https://hex.pm/docs/publish). The package can be installed
by adding `type_check` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:type_check, "~> 0.12.1"},
    # To allow spectesting and property-testing data generators (optional):
    {:stream_data, "~> 0.5.0", only: :test}, 
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

On a superficial level, Norm and TypeCheck seem similar. However, there are [important differences in their design considerations](https://github.com/Qqwy/elixir-type_check/blob/master/Comparing%20TypeCheck%20and%20Norm.md).


## Is it any good?

[yes](https://news.ycombinator.com/item?id=3067434)
