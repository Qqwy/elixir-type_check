# TypeCheck


## Roadmap

- [x] Proof and implementation of the basic concept
- [x] Custom type definitions (type, typep, opaque)
  - [x] Basic
  - [x] Parameterized
- [ ] Hide implementation of `opaque` from documentation
- [x] Spec argument types checking
- [x] Spec return type checking
- [ ] Spec possibly named arguments
- [ ] Implementation of Elixir's builtin types
  - [ ] Primitive types
  - [ ] Compound types
  - [ ] special forms like `:;`, `|`, etc.
  - [ ] Overrides for builtin typedefs (`String.t`,`Enum.t`, etc.)
- [ ] Creating generators from types
- [ ] Creating generators from specs
  - [ ] Wrap spec-generators so you have a single statement to call in the test suite which will prop-test your function against all allowed inputs/outputs.
- [ ] Configurable setting to turn on/off at compile-time, and maybe dynamically at run-time (with slight performance penalty).


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

