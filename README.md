# TypeCheck: Fast and flexible runtime type-checking for your Elixir projects.


## Core ideas

- Type- and function specifications are constructed using (essentially) the **same syntax** as built-in Elixir Typespecs.
- When a value does not match a type check, the user is shown **human-friendly error messages**.
- Types and type-checks are generated at compiletime.
  - This means **type-checking code is optimized** rigorously by the compiler.
- Property-checking generators can be extracted from type specifications without extra work.
- Flexibility to add custom checks: Subparts of a type can be named, and 'type guards' can be specified to restrict what values are allowed to match that refer to these types.


## Usage

```elixir
defmodule YourModule do
  # Add TypeCheck-capabilities to your module:
  use TypeCheck
  
  # Now, you can use the `spec`-macro to add runtime-checks
  # to your functions.
  spec wrap_numbers_in_list(number()) :: [number()]
  def wrap_numbers_in_list(x) do
    [x]
  end
  
  # `spec` accepts the same syntax as Elixir's builtin `@spec`.

  # Similarly, the `type`, `typep` and `opaque` macros are available
  # to construct your own public- or private types:
  type mylist :: list(integer())
  
  # If wanted, type guards can be added for more flexibility:
  type nonzero :: (val :: integer()) when val != 0
  type sorted_pair(a, b) :: {first :: a, second :: b} when first <= second
end
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


### Pre-stable

- [ ] Detailed documentation.
- [ ] Rigorous tests.
- [ ] referring to variables in outer scope using pin operator (?)
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

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `type_check` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:type_check, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/type_check](https://hexdocs.pm/type_check).

