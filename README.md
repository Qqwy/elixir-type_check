# TypeCheck


## Roadmap

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
  - [ ] More primitive types
  - [x] Compound types
  - [x] special forms like `|`, `a..b` etc.
  - [ ] Overrides for builtin typedefs (`String.t`,`Enum.t`, etc.)
  - [x] Literal lists
  - [x] Maps with keys => types
  - [x] Structs with keys => types
  - [ ] More map/list-based structures.
- [x] A `when` to add guards to typedefs for more power.
- [x] Make errors raised when types do not conform humanly readable
  - [ ] Improve readability of spec-errors by repeating spec and which parameter did not match.
- [x] Creating generators from types
- [ ] Creating generators from specs
  - [ ] Wrap spec-generators so you have a single statement to call in the test suite which will prop-test your function against all allowed inputs/outputs.
- [ ] Configurable setting to turn on/off at compile-time, and maybe dynamically at run-time (with slight performance penalty).
- [ ] Per-module settings to turn on/off, configure formatter, etc.

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

