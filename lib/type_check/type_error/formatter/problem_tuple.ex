# defmodule TypeCheck.TypeError.ProblemTuple do
#   use TypeCheck
#   type problem_tuple :: one_of([
#     TypeCheck.Builtin.Any.problem_tuple_type,
#     TypeCheck.Builtin.Atom.problem_tuple_type,
#     TypeCheck.Builtin.Binary.problem_tuple_type,
#     TypeCheck.Builtin.Bitstring.problem_tuple_type,
#   ])
# end
