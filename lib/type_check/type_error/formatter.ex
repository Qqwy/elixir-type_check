defmodule TypeCheck.TypeError.Formatter do
  @moduledoc """
  Behaviour to format your own type errors
  """

  @doc """
  Takes an 'explanation tuple' as input

  and is expected to return a string.

  An `explanation tuple` contains four fields:

  1. the module of the type for which a check did not pass
  2. an atom describing the exact error;
     for many types there are multiple checks
  3. a map with fields containing extra information about the error.
     in the cases of a compound type, this often contains information
     about the deeper problem that happened as well.
  4. the datastructure that did not pass the check


  See the module documentation of all `TypeCheck.Builtin.*` modules
  for more information about the checks that they perform and the explanation tuples they might return.
  """
  @callback format(explanation_tuple :: {module(), atom(), map(), any()}) :: String.t()
end
