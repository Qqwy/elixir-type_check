defmodule TypeCheck.TypeError.Formatter do
  @moduledoc """
  Behaviour to format your own type errors
  """

  @typedoc """
  A `problem tuple` contains four fields:

  1. the module of the type for which a check did not pass
  2. an atom describing the exact error;
     for many types there are multiple checks
  3. a map with fields containing extra information about the error.
     in the cases of a compound type, this often contains information
     about the deeper problem that happened as well.
  4. the datastructure that did not pass the check


  See the module documentation of all `TypeCheck.Builtin.*` modules
  for more information about the checks that they perform and the problem tuples they might return.
  """
  # @type problem_tuple :: {module(), atom(), map(), any()}
  # use TypeCheck
  # type problem_tuple :: {module, atom, map, any}
  use TypeCheck

  @type! problem_tuple ::
         # TypeCheck.Builtin.Any.problem_tuple()
          TypeCheck.Builtin.Atom.problem_tuple()
         | TypeCheck.Builtin.Binary.problem_tuple()
         | TypeCheck.Builtin.Bitstring.problem_tuple()
         | TypeCheck.Builtin.Boolean.problem_tuple()
         | TypeCheck.Builtin.FixedList.problem_tuple()
         | TypeCheck.Builtin.FixedMap.problem_tuple()
         | TypeCheck.Builtin.FixedTuple.problem_tuple()
         | TypeCheck.Builtin.Float.problem_tuple()
         | TypeCheck.Builtin.Integer.problem_tuple()
         # # | TypeCheck.Builtin.Lazy.problem_tuple # Problem
         # | TypeCheck.Builtin.List.problem_tuple() # Problem
         | TypeCheck.Builtin.Literal.problem_tuple()
         # | TypeCheck.Builtin.Map.problem_tuple() # Problem
         # | TypeCheck.Builtin.NamedType.problem_tuple() # Problem
         | TypeCheck.Builtin.NegInteger.problem_tuple()
         | TypeCheck.Builtin.NonNegInteger.problem_tuple()
         | TypeCheck.Builtin.None.problem_tuple()
         | TypeCheck.Builtin.Number.problem_tuple()
         # # | TypeCheck.Builtin.OneOf.problem_tuple # Problem
         | TypeCheck.Builtin.PosInteger.problem_tuple()
         | TypeCheck.Builtin.Range.problem_tuple()
         | TypeCheck.Builtin.Tuple.problem_tuple()

  @doc """
  A formatter is expected to turn a `problem_tuple` into a string
  that can be used as `:message` of the TypeCheck.TypeError exception.
  """
  @callback format(problem_tuple, TypeCheck.TypeError.location()) :: String.t()
end
