# Comparing TypeCheck and Elixir Typespecs

TypeCheck is intended to be a drop-in supplement to Elixir typespecs. Not all typespec syntax is supported in TypeCheck, but the majority of common syntax is and this gap continues to shrink. Below is a breakdown of supported typespec syntax in TypeCheck.

In the tables below:
- '✅' indicates that something is supported
- '❌' indicates that something is not supported.
- '⌛' indicates that something is not currently supported, but there are plans to add support for it in the near future.


## Basic Types

| Type                                                         | Supported? | Notes                              |
|--------------------------------------------------------------|------------|------------------------------------|
| any()                                                        | ✅         | the top type, the set of all terms |
| none()                                                       | ✅         | the bottom type, contains no terms |
| atom()                                                       | ✅         |                                    |
| map()                                                        | ✅         | any map                            |
| pid()                                                        | ✅         | process identifier                 |
| port()                                                       | ⌛         | port identifier                    |
| reference()                                                  | ⌛         |                                    |
| tuple()                                                      | ✅         | tuple of any size                  |
| float()                                                      | ✅         |                                    |
| integer()                                                    | ✅         |                                    |
| neg_integer()                                                | ✅         | ..., -3, -2, -1                    |
| non_neg_integer()                                            | ✅         | 0, 1, 2, 3, ...                    |
| pos_integer()                                                | ✅         | 1, 2, 3, ...                       |
| list(type)                                                   | ✅         | proper list                        |
| nonempty_list(type)                                          | ✅         | non-empty proper list              |
| maybe_improper_list(content_type, termination_type)          | ⌛         | proper or improper list            |
| nonempty_improper_list(content_type, termination_type)       | ⌛         | improper list                      |
| nonempty_maybe_improper_list(content_type, termination_type) | ⌛         | non-empty proper or improper list  |

## Literals

| Type                                | Supported? | Notes                                              |
|-------------------------------------|------------|----------------------------------------------------|
| :atom                               | ✅         | atoms: :foo, :bar, ...                             |
| true                                | ✅         |                                                    |
| false                               | ✅         |                                                    |
| nil                                 | ✅         |                                                    |
| <<>>                                | ⌛         | empty bitstring                                    |
| <<_::size>                          | ⌛         | size is 0 or a positive integer                    |
| <<_::_*unit>>                       | ⌛         | unit is an integer from 1 to 256                   |
| <<_::size, _::_*unit>>              | ⌛         |                                                    |
| (-> type)                           | ❌¹        | 0-arity, returns type                              |
| (type1, type2 -> type)              | ❌¹        | 2-arity, returns type                              |
| (... -> type)                       | ❌¹        | any arity, returns type                            |
| 1                                   | ✅         | integer                                            |
| 1..10                               | ✅         | range                                              |
| [type]                              | ✅         | list with any number of type elements              |
| []                                  | ✅         | empty list                                         |
| [...]                               | ✅         | shorthand for nonempty_list(any())                 |
| [type, ...]                         | ✅         | shorthand for nonempty_list(type)                  |
| [key: value_type]                   | ✅         | keyword list with key :key of value_type           |
| %{}                                 | ✅         | empty map                                          |
| %{key: value_type}                  | ✅         | map with required key :key of value_type           |
| %{key_type => value_type}           | ⌛         | map with required pairs of key_type and value_type |
| %{required(key_type) => value_type} | ⌛         | map with required pairs of key_type and value_type |
| %{optional(key_type) => value_type} | ⌛         | map with optional pairs of key_type and value_type |
| %SomeStruct{}                       | ✅         | struct with all fields of any type                 |
| %SomeStruct{key: value_type}        | ✅         | struct with required key :key of value_type        |
| {}                                  | ✅         | empty tuple                                        |
| \{:ok, type\}                       | ✅         | two-element tuple with an atom and any type        |

¹: Supporting function-arguments is tricky. However, it definitely is a desired feature.
Help or ideas to make this work are greatly appreciated. [This feature is discussed here](https://github.com/Qqwy/elixir-type_check/issues/6).

## Built-in types

| Type                           | Supported? | Notes                                                               |
|--------------------------------|------------|---------------------------------------------------------------------|
| term()                         | ✅         | any()                                                               |
| arity()                        | ✅         | 0..255                                                              |
| as_boolean(t)                  | ✅         | t                                                                   |
| binary()                       | ✅         | <<_::_*8>>                                                          |
| bitstring()                    | ✅         | <<_::_*1>>                                                          |
| boolean()                      | ✅         | true \| false                                                       |
| byte()                         | ✅         | 0..255                                                              |
| char()                         | ✅         | 0..0x10FFFF                                                         |
| charlist()                     | ✅         | [char()]                                                            |
| nonempty_charlist()            | ⌛         | [char(), ...]                                                       |
| fun()                          | ✅         | (... -> any)                                                        |
| function()                     | ✅         | fun()                                                               |
| identifier()                   | ⌛         | pid() \| port() \| reference()                                      |
| iodata()                       | ⌛         | iolist() \| binary()                                                |
| iolist()                       | ⌛         | maybe_improper_list(byte() \| binary() \| iolist(), binary() \| []) |
| keyword()                      | ✅         | [{atom(), any()}]                                                   |
| keyword(t)                     | ✅         | [{atom(), t}]                                                       |
| list()                         | ✅         | [any()]                                                             |
| nonempty_list()                | ✅         | nonempty_list(any())                                                |
| maybe_improper_list()          | ⌛         | maybe_improper_list(any(), any())                                   |
| nonempty_maybe_improper_list() | ⌛         | nonempty_maybe_improper_list(any(), any())                          |
| mfa()                          | ✅         | {module(), atom(), arity()}                                         |
| module()                       | ✅         | atom()                                                              |
| no_return()                    | ✅         | none()                                                              |
| node()                         | ⌛         | atom()                                                              |
| number()                       | ✅         | integer() \| float()                                                |
| struct()                       | ⌛         | %{:__struct__ => atom(), optional(atom()) => any()}                 |
| timeout()                      | ⌛         | :infinity \| non_neg_integer()                                      |

## 🚀 TypeCheck Additions

TypeCheck adds the following extensions on Elixir's builtin typespec syntax:


| Type                      | Notes                                                                    |
|---------------------------|--------------------------------------------------------------------------|
| impl(protocol_name)       | Checks whether the given value implements the particular protocol        |
| fixed_list(element_types) | Fixed size where element_types dictate types                             |
| tuple(size)               | Any types, but which has exactly size elements                           |
| map(key_type, value_type) | Zero or more keys of key_type and values of value_type                   |
| type when guard           | A 'type guard', an extra check implemented in arbitrary code (see below) |

## Defining Specifications

| Type    | Supported? | Notes       |
|---------|------------|-------------|
| @type   | ✅         | as @type!   |
| @opaque | ✅         | as @opaque! |
| @typep  | ✅         | as @typep!  |
| @spec   | ✅         | as @spec!   |

✅ **Basic Spec Definition**

```elixir
# typespecs
@spec function_name(type1, type2) :: return_type

# TypeCheck
@spec! function_name(type1, type2) :: return_type
```

❌ **Spec Guards**

```elixir
# typespecs
@spec function(arg) :: [arg] when arg: atom
@spec function(arg1, arg2) :: {arg1, arg2} when arg1: atom, arg2: integer
@spec function(arg) :: [arg] when arg: var

# TypeCheck - unsupported
```

TypeCheck currently solely allows the usage of `when` to specify 'type guards' (see below).
Support for spec guards could be added. However:
- Their usage is quite rare.
- Each place where it is used, it matches 'exactly the same value'. Building this check is relatively tricky.

If you have a strong desire for this feature, please open an issue for it.

✅ **Named Arguments**

```elixir
# typespecs
@spec days_since_epoch(year :: integer, month :: integer, day :: integer) :: integer
@type color :: {red :: integer, green :: integer, blue :: integer}

# TypeCheck
@spec! days_since_epoch(year :: integer, month :: integer, day :: integer) :: integer
@type! color :: {red :: integer, green :: integer, blue :: integer}
```

❌ **Specification Overloads**

```elixir
# typespecs
@spec function(integer) :: atom
@spec function(atom) :: integer

# TypeCheck - unsupported
```

There is no intention to support this.
The implementation would be very difficult, and it is arguably good practice to have a single specification anyway.


### User Defined Types

✅ **Basic Definition**

```elixir
# typespecs
@type type_name :: type
@typep type_name :: type
@opaque type_name :: type

# TypeCheck
@type! type_name :: type
@typep! type_name :: type
@opaque! type_name :: type
```

✅ **Parameterized Types**

```elixir
# typespecs
@type dict(key, value) :: [{key, value}]

# TypeCheck
@type! dict(key, value) :: [{key, value}]
```

🚀 **Type Guards**

To add extra custom checks to a type, you can use a so-called 'type guard'. This is arbitrary code that is executed during a type-check once the type itself already matches.

You can use "named types" to refer to (parts of) the value that matched the type, and refer to these from a type-guard:

```elixir
# typespecs - unsupported

# TypeCheck
@type! sorted_pair :: {lower :: number(), higher :: number()} when lower <= higher
```

## 🟨 Remote Types

It is often useful to refer to types defined in other modules. These are called 'Remote types'.
Elixir's typespecs and TypeCheck both support remote types.

```elixir
# typespecs
defmodule User do
  @type t() :: %User{name: String.t(), age: non_negative_integer()}
end

defmodule Greeter do
  @spec greet(User.t()) :: String.t()
  def greet(user) do
   # ... 
  end
end

# TypeCheck
defmodule User do
  use TypeCheck

  @type! t() :: %User{name: String.t(), age: non_negative_integer()}
end

defmodule Greeter do
  use TypeCheck

  @spec! greet(User.t()) :: String.t()
  def greet(user) do
   # ... 
  end
end
```


### Remote Type Overrides

From time to time we need to interface with modules written in other libraries (or the Elixir standard library) which do not expose their types through TypeCheck yet.
We want to be able to use those types in our checks, but they exist in modules that we cannot change ourselves.

The solution is to allow a list of ‘type overrides’ to be given as part of the options passed to use TypeCheck, which allow you to use the original type in your types and documentation, but have it be checked (and potentially property-generated) as the given TypeCheck-type.

Example:

```elixir
defmodule Original do
  @type t() :: any()
end

defmodule Replacement do
  use TypeCheck
  @type! t() :: integer()
end

defmodule Example do
  use TypeCheck, overrides: [{&Original.t/0, &Replacement.t/0}]

  @spec! times_two(Original.t()) :: integer()
  def times_two(input) do
    input * 2
  end
end
```

### Elixir Standard Library Types

TypeCheck helpfully ships with the majority of the types in Elixir's Standard Library already implemented as default overrides. This means that your `@spec!` definitions can reference types like `String.t()`, `Date.t()` and `Range.t()` out of the box.


| Type                      | Supported? | Notes      |
|---------------------------|------------|------------|
| Access                    | ✅         |            |
| Agent                     | ⌛         |            |
| Application               | ⌛         |            |
| Calendar                  | ✅         |            |
| Calendar.ISO              | ✅         |            |
| Calendar.TimeZoneDatabase | ⌛         |            |
| Code                      | ⌛         |            |
| Collectable               | ✅         |            |
| Config.Provider           | ⌛         |            |
| Date                      | ✅         |            |
| Date.Range                | ✅         |            |
| DateTime                  | ✅         |            |
| Dict                      | ❌         | deprecated |
| DynamicSupervisor         | ⌛         |            |
| Enum                      | ✅         |            |
| Enumerable                | ✅         |            |
| Exception                 | ✅         |            |
| File                      | ✅         |            |
| File.Stat                 | ✅         |            |
| File.Stream               | ✅         |            |
| Float                     | ✅         |            |
| Function                  | ✅         |            |
| GenEvent                  | ❌         | deprecated |
| GenServer                 | ⌛         |            |
| HashDict                  | ❌         | deprecated |
| HashSet                   | ❌         | deprecated |
| IO                        | ✅         |            |
| IO.ANSI                   | ⌛         |            |
| IO.Stream                 | ⌛         |            |
| Inspect                   | ✅         |            |
| Inspect.Algebra           | ⌛         |            |
| Inspect.Opts              | ⌛         |            |
| Keyword                   | ✅         |            |
| List.Chars                | ⌛         |            |
| Macro                     | ⌛         |            |
| Macro.Env                 | ⌛         |            |
| Map                       | ✅         |            |
| MapSet                    | ✅         |            |
| NaiveDateTime             | ✅         |            |
| Node                      | ⌛         |            |
| OptionParser              | ⌛         |            |
| Path                      | ⌛         |            |
| Port                      | ⌛         |            |
| Process                   | ⌛         |            |
| Range                     | ✅         |            |
| Regex                     | ✅         |            |
| Registry                  | ⌛         |            |
| Set                       | ❌         | deprecated |
| Stream                    | ✅         |            |
| String                    | ✅         |            |
| String.Chars              | ⌛         |            |
| Supervisor                | ⌛         |            |
| Supervisor.Spec           | ❌         | deprecated |
| System                    | ⌛         |            |
| Task                      | ⌛         |            |
| Task.Supervisor           | ⌛         |            |
| Time                      | ✅         |            |
| URI                       | ✅         |            |
| Version                   | ✅         |            |
| Version.Requirement       | ✅         |            |

