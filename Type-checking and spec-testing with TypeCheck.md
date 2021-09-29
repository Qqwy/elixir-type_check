![](https://raw.githubusercontent.com/Qqwy/elixir-type_check/master/media/type_check_logo_flat.svg)

# Type-checking and spec-testing with TypeCheck

[TypeCheck](https://hex.pm/packages/type_check) is an elixir library to, you guessed it, check the types of the values, variables and functions in your Elixir projects.

Elixir is a strong, dynamically typed programming language. 
'Strong' (as opposed to 'weak') means that when we try to perform an unsupported operation on a value (like 'multiplying strings'), we get an error, rather than silent faulty behaviour.
'Dynamic' (as opposed to 'Static') means that which operations we do with our values is not checked at compile-time, but only once the program itself is running.

However, when such a failure happens at runtime, the resulting error (and more importantly: what the _cause_ was of an error) is not always very clear.
Is it a bug in your code? Or a bug in a library you are using?
Where in the deeply nested tree of structs is the problem that results in a `** (BadFunctionError) expected a function, got: nil` somewhere deep inside the codebase?

Related to this, we would like to catch problems early in the development cycle: if we find an error while writing our code initially,
then fixing it takes significantly less effort (and is much less costly) than if the problem happens in an application which is already deployed to production.


TypeCheck gives you the handholds to tackle this situation.

## What about Elixir's built-in typespecs and Dialyzer?

Elixir (and Erlang) come with a nice description for the types of the values passed between functions, called ['Typespecs'](https://hexdocs.pm/elixir/master/typespecs.html).
However, by default these typespecs are just used for documentation. 
They are not used in any way to restrict, or even warn when your code is not following them correctly.

Somewhat more recently, tools like [Dialyzer / Dialyzir](https://github.com/jeremyjh/dialyxir) have been introduced in the ecosystem.
These perform a static check of the source-code (that is, they look at the code as written without executing it) to catch some potential mis-uses.
Dialyzer has however three commonly mentioned drawbacks:

1. On larger codebases it becomes prohibitively slow to run;
2. It contains both 'false negatives' (improper usage that it missed) as well as 'false positives' (warnings about things which are actually OK);
3. Some warnings can be outright cryptic to resolve.

Dialyzer is still a very useful tool, but it is not a cure-all.
As such, there was definite room in this space for improvement.

## Introducing TypeCheck

Using TypeCheck is as simple as adding a `use TypeCheck` to the module(s) you want to add checks to.

For each type-specification ('type') and function-specification ('spec') which is defined using TypeCheck, the following four features become available:

1. 'Normal' Elixir Typespecs for usage with pre-existing external tools (like e.g. Dialyzer).
2. Documentation with extra detail not found in 'Normal' Elixir typespecs.
3. Run-time type checks for all parameters to a function (if there is a failure, the function is used improperly) and of the returned value (if this fails, the function has a mistake).
4. Data generators for all types (and specs), for usage in testing, especially property-tests and spectests (explained below).

Let's take a look at how TypeCheck can be used in practice. 
This will help to see how the run-time type checks work, as well as how you can use TypeCheck's spectests to supercharge your testing.


## An Example

Let's say we are writing a module to work with five-star ratings.

```elixir
defmodule Rating do
  @type t() :: %Rating{value: 1..5, author: String.t()}
  defstruct [:value, :author]
  
  @spec average(list(t())) :: number()
  def average(ratings) do
    values = Enum.map(ratings, &(&1.value))
    Enum.sum(values) / Enum.count(values)
  end
end
```

In good Elixir style, the functions and the struct have already received type signatures, even though they are currently only used for documentation.
(Speaking of documentation: it is good practice to add documentation to all public modules and functions. To keep the examples in this article brief, they have been elided.)

From the function-specification, you can already see how the function `average` is intended to be used:
When passing a list of ratings, we will return a single number: the average.


Let's try calling it with a couple of inputs:


```elixir
iex(8)> Rating.average([%Rating{author: "Joe", value: 5}, %Rating{author: "Mike", value: 4}])
4.5
iex(8)> Rating.average([%Rating{author: "Robert", value: 3}])
3.0
```

So far so good.
Now, let's try what happens when someone makes a mistake:

```elixir
iex> Rating.average(%Rating{author: "José", value: 3})
** (Protocol.UndefinedError) protocol Enumerable not implemented for %Rating{author: "José", value: 3} of type Rating (a struct). This protocol is implemented for the following type(s): Map, Range, List, MapSet, GenEvent.Stream, Stream, Date.Range, HashDict, IO.Stream, HashSet, Function, File.Stream
    (elixir 1.12.0) lib/enum.ex:1: Enumerable.impl_for!/1
    (elixir 1.12.0) lib/enum.ex:141: Enumerable.reduce/3
    (elixir 1.12.0) lib/enum.ex:3923: Enum.map/2
    iex:19: Rating.average/1
```

Oof!
Clearly something is going wrong here, but if one were to encounter this error somewhere deep in a codebase,
it would not be immediately obvious that the problem was that we were calling the function incorrectly.

Even worse is if we happen to pass a list of non-ratings to the function:

```elixir
iex> Rating.average([1, 2, 3])
** (ArgumentError) you attempted to apply :value on 1. If you are using apply/3, make sure the module is an atom. If you are using the dot syntax, such as map.field or module.function(), make sure the left side of the dot is an atom or a map
    :erlang.apply(1, :value, [])
    iex:19: anonymous fn/1 in Rating.average/1
    (elixir 1.12.0) lib/enum.ex:1553: Enum."-map/2-lists^map/1-0-"/2
    iex:19: Rating.average/1
```

And finally, there is nothing preventing the creation of malformed rating-objects.
While we have specified in our type that the rating's value should only ever be in the range 1..5,
this is not constrained anywhere in the code. 

And if someone passes a `nil` rating, we'd get a `** (ArithmeticError) bad argument in arithmetic expression: nil + 0` error. 
Also not very clear.

While we could sprinkle checks for this everywhere, this would in the best case result in extremely 'defensive' and badly readable code.
And in the worst case, we might forget to add a the check at certain places, still not giving us certainty.


Let's see how TypeCheck can improve this situation. 


## Adding TypeCheck


In general, adding TypeCheck to a module only requires the following two steps:
1. Add `use TypeCheck` at the top of the module.
2. Replace all usage of `@type` with `@type!` and all usage of `@spec` with `@spec!`. (For the curious: There indeed are similarly overloaded versions of `@typep!` and `@opaque!` available.)

You're done!
Our example ratings module now looks like this:

```elixir
defmodule Rating do
  use TypeCheck

  @type! t() :: %Rating{value: 1..5, author: String.t()}
  defstruct [:value, :author]
  
  @spec! average(list(t())) :: number()
  def average(ratings) do
    values = Enum.map(ratings, &(&1.value))
    Enum.sum(values) / Enum.count(values)
  end
end
```

With this change, correct usage of the function still returns the expected results:

```elixir
iex(8)> Rating.average([%Rating{author: "Joe", value: 5}, %Rating{author: "Mike", value: 4}])
4.5
iex(8)> Rating.average([%Rating{author: "Robert", value: 3}])
3.0
```

So far, so good. Now let's look at what happens when the function is used incorrectly:


```elixir
iex(20)> Rating.average(%Rating{author: "José", value: 3})
** (TypeCheck.TypeError) At iex:17:
    The call to `average/1` failed,
    because parameter no. 1 does not adhere to the spec `list(%Rating{author: binary(), value: number()})`.
    Rather, its value is: `%Rating{author: "José", value: 3}`.
    Details:
      The call `average(%Rating{author: "José", value: 3})`
      does not adhere to spec `average(list(%Rating{author: binary(), value: number()})) :: number()`. Reason:
        parameter no. 1:
          `%Rating{author: "José", value: 3}` does not check against `list(%Rating{author: binary(), value: number()})`. Reason:
            `%Rating{author: "José", value: 3}` is not a list.
        lib/type_check/spec.ex:165: Rating.average/1

```

Look at that! Not only do we see that the problem is is caused by the call to the function itself,
but the cause of the problem is also very clear: the passed value is not a list.


Here's our second mistake:

```elixir
iex> Rating.average([1, 2, 3])
** (TypeCheck.TypeError) At iex:17:
    The call to `average/1` failed,
    because parameter no. 1 does not adhere to the spec `list(%Rating{author: binary(), value: number()})`.
    Rather, its value is: `[1, 2, 3]`.
    Details:
      The call `average([1, 2, 3])`
      does not adhere to spec `average(list(%Rating{author: binary(), value: number()})) :: number()`. Reason:
        parameter no. 1:
          `[1, 2, 3]` does not check against `list(%Rating{author: binary(), value: number()})`. Reason:
            at index 0:
              `1` does not check against `%Rating{author: binary(), value: number()}`. Reason:
                `1` is not a map.
        lib/type_check/spec.ex:165: Rating.average/1

```

This time too, the error is much clearer, showing that the innermost reason of the type-checking failure is that the passed number is not a map.

Now, let's also look at what happens when we pass a malformed `Rating` struct:


```elixir
iex> Rating.average([%Rating{author: "root", value: -100}])
** (TypeCheck.TypeError) At iex:21:
    The call to `average/1` failed,
    because parameter no. 1 does not adhere to the spec `list(%Rating{author: binary(), value: 1..5})`.
    Rather, its value is: `[%Rating{author: "root", value: -100}]`.
    Details:
      The call `average([%Rating{author: "root", value: -100}])`
      does not adhere to spec `average(list(%Rating{author: binary(), value: 1..5})) :: number()`. Reason:
        parameter no. 1:
          `[%Rating{author: "root", value: -100}]` does not check against `list(%Rating{author: binary(), value: 1..5})`. Reason:
            at index 0:
              `%Rating{author: "root", value: -100}` does not check against `%Rating{author: binary(), value: 1..5}`. Reason:
                under key `:value`:
                  `-100` does not check against `1..5`. Reason:
                    `-100` falls outside the range 1..5.
        lib/type_check/spec.ex:165: Rating.average/1

```

Much nicer! Now, all functions which have a `@spec!` will have there inputs checked properly,
and passing them a malformed rating-struct is impossible without cluttering our code.


As a final example, say we alter the implementation of the function to something which is clearly wrong,
such as always returning the string `"something else"`:

```elixir
iex> Rating.average([%Rating{author: "Joe", value: 5}, %Rating{author: "Mike", value: 4}])
** (TypeCheck.TypeError) The call to `average/1` failed,
    because the returned result does not adhere to the spec `number()`.
    Rather, its value is: `"something else"`.
    Details:
      The result of calling `average([%Rating{author: "Marten", value: 1}])`
      does not adhere to spec `average(
      list(%Rating{author: binary(), value: 1..5})) :: number()`. Reason:
        Returned result:
          `"something else"` is not a number.
        lib/type_check/spec.ex:194: Rating.average/1
```

In this case, you can clearly see that the problem is caused by the return value, and why.


## Efficiency of runtime checks

TypeCheck adds its runtime checks by wrapping your functions (using [`defoverridable`](https://hexdocs.pm/elixir/1.9.1/Kernel.html?#defoverridable/1)).
This means that the Elixir and Erlang compilers are able to optimize the checks to their liking.
Therefore, code addd by TypeCheck is at the very least not slower than any hand-written parameter-checking code.
In many cases, the compiler is even smart enough to combine the type-check with a `case`, `if` or `cond`-expression that your function implementation itself contains, 
so even in those cases no duplicate checks are done.

That said, there are certain cases in which the type-checks might still be too slow, since by default TypeCheck performs a deep check for
all parameters to a function. In the case of for instance a large collection or a deeply-nested 'tree of structs' this might still be too slow.

In those cases, you might want to turn off TypeCheck in certain environments (such as production) while still keeping it available in the development and testing environments.
Be sure to benchmark before making the decision to turn TypeCheck off, as there is a high probability that the bottlenecks in your code are actually found elsewhere.
_(Note: Turning off checks conditionally is a feature which [is currently being worked on](https://github.com/Qqwy/elixir-type_check/issues/52). It will be available in the next minor version of the library.)_

And finally, regardless of whether the checks are used or not, there is one more way in which TypeCheck's types and specs are useful: Automated testing.



## Spectests


Runtime type-checks give an early notice whether a function is being used properly or improperly.
In essence, we check 'Does the caller of the function adhere to the function's specification?'
However, to get more certainty about the correctness¹ of our code, we'd also like to check the opposite: 'Does the function itself adhere to its specification?'

This is where 'function-specification tests', or _spectests_ for short, come in.

### What is a spectest?

A spectest is a property-based test in which
we check whether the function adheres to its specifcation's _invariants_
(also known as the function's _contract_ or its _preconditions and postconditions_).

This is done by generating a large amount of possible function inputs,
and for each of these, check whether the function:
- Does not raise an exception.
- Returns a result that type-checks against the spec's return-type.

Spectests are given its own test-category in ExUnit, for easier recognition
(Just like 'doctests' and 'properties' are different from normal tests, so are 'spectests'.)




If you're new to property-based testing, then ['Overview of Property-based testing'](https://hexdocs.pm/stream_data/ExUnitProperties.html#module-overview-of-property-based-testing)-section of the ExUnitProperties' documentation
might be a good place for a general overview.

<small>
¹: Because of the nature of property-based testing, we can never know for 100% sure that a function is correct. However, with every new randomly-generated test-case, the level of confidence grows a little. So while we can never by <em>fully</em> sure, we are able to get asymptotically close to it.
</small>

### Spectesting our example

To add a spectest, we need to `use TypeCheck.ExUnit` in our testing file,
and then call `spectest YourModuleName`. This accepts options similarly to [`doctest`](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html#doctest/2) which you might already be familiar with.

To use spectests (and data generation in general), TypeCheck requires on the optional dependency [`StreamData`](https://hex.pm/packages/stream_data),
so be sure to add it to your project's mix deps.

Let's spectest the `Rating` module, to make sure our code does not contain any mistakes.

```elixir
defmodule RatingTest do
  use ExUnit.Case, async: true
  use TypeCheck.ExUnit

  spectest Rating
end
```

```elixir
$ mix test


  1) spectest average(list(%Rating{author: binary(), value: 1..5})) :: number() (RatingTest)
     test/rating_test.exs:5
     Spectest failed (after 0 successful runs)
     
     Input: Rating.average([])
     
     ** (ArithmeticError) bad argument in arithmetic expression
     
     code: #TypeCheck.Spec<  average(list(%Rating{author: binary(), value: 1..5})) :: number() >
     stacktrace:
       (type_check_guide 0.1.0) lib/rating.ex:10: Rating."average (overridable 1)"/1
       lib/type_check/ex_unit.ex:5: anonymous fn/1 in RatingTest."spectest average(\n  list(%Rating{author: binary(), value: 1..5})\n)\n::\nnumber()"/1
       (stream_data 0.5.0) lib/stream_data.ex:2102: StreamData.check_all/7
       lib/type_check/ex_unit.ex:5: (test)

..

Finished in 0.1 seconds (0.1s async, 0.00s sync)
1 doctest, 1 spectest, 1 test, 1 failure
```


Oof! Our code contained a mistake!
It turns out that when `Rating.average` is given an empty list, we end up dividing by zero!

Some math-savvy readers might have seen this coming from a mile away.
However, I'm sure that _some_ of you will have been surprised by this problem 😇.
Of course this is only an educational example of the kind of issues one might encounter in a _real_ codebase.

We might resolve this issue in two ways:
- Decide that an empty list should never be passed, and therefore testrict the parameter types further. 
  For instance, we could change it from a `list(Rating.t())` to a `nonempty_list(Rating.t())`.
  This means that when someone tries passing it an empty list, they will immediately be notified that this is not supported,
  using the clear error messages as seen in the earlier examples. 
  Changing the spec this way will also make the spectest pass, as empty lists will no longer be generated.
- Decide that empty lists are a correct input, but that the output will be changed from `number()` to `{:ok, number()} | {:error, :empty}`,
  asking code which uses `average` to handle the possibility of an error-result being returned.

In either case, after these changes the spectest will pass.

## More general properties

While spectests are a very simple and code-light way to test your functions,
it is also possible to generate arbitrary values from any type outside of a `spectest`, for use in other, more specialized property-based tests.
See [TypeCheck.Type.StreamData.to_gen/1](https://hexdocs.pm/type_check/TypeCheck.Type.StreamData.html#to_gen/1) for more info.

## There is more

We have covered the most important features of TypeCheck,
but there is more to discover, such as:

- The error-formatter which [is reconfigurable](https://hexdocs.pm/type_check/TypeCheck.TypeError.Formatter.html) and could be overloaded by custom implementations.
- TypeCheck itself is extensively property-tested using its own types.
- Most of TypeCheck's type-construction functions use TypeCheck's checks itself, which mean that you will get the same clear error messages when making a mistake while constructing a type (but this time during _compile-time_. nifty, eh?!)
- TypeCheck supports ['type guards'](https://hexdocs.pm/type_check/TypeCheck.Builtin.html#guarded_by/2) for if you want to add extra custom constraints to any particular type.
- TypeCheck supports ['unquote fragments'](https://hexdocs.pm/type_check/TypeCheck.Macros.html#module-typecheck-and-metaprogramming) for when you want to go ham with metaprogramming.

## Summary

In this guide, you have seen how TypeCheck can be used and what value it can add to your projects.
We have seen how TypeCheck can be used in a general project to add runtime checks to your functions,
as well as how to use the `spectest` macro to get automatic property-tests that check whether your functions 
follow their specs.

TypeCheck currently is at version 0.6.0 and in active development.
Feedback, issues and pull requests [are very welcome](https://github.com/Qqwy/elixir-type_check)!

Thank you very much for sticking through this long read with me 💚.
I wish you a wonderful day!

~Marten/Qqwy
