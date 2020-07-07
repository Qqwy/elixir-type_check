### Norm

[Norm](https://github.com/keathley/norm/) is an Elixir library for specifying the structure of data that can be used for both validation and data-generation.

On a superficial level, Norm and TypeCheck seem similar. However, there are important differences in their design considerations:

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

---

Norm and TypeCheck are but two different dots in the datastructure-validation design space. Norm is definitely worth checking out!
