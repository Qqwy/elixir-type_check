defmodule TypeCheck.Options.Check do
  @type t :: %__MODULE__{enabled: boolean(), depth: (non_neg_integer() | :infinity)}
  @doc """
  - `enabled:` if `false`, no checks will be added to the source code (default: `true`).
  - `depth:` configures how much work TypeCheck will do during type-checking for container types.
     Can either be `:infinity` or a nonnegative integer.
     Default: `:infinity` (test everything).
     If the depth is `0`, no more checking is done.

  ## The `:depth` option

  If the depth is `0`, no check is done.
  For any other depth, we perform checks.
  For recursive datatypes (i.e. maps, lists and tuples), TypeCheck will perform checking outside-in, with elements being checked with a lower depth.

  The idea is here that if we have a deeply nested datatype, we don't test everything but instead only the outermost (couple of) layer(s),
  with the assumption that innermore datatypes will be checked in later specs anyway.

  In this way we can reduce the amount of 'repetitive' (and therefore less useful) checking-work that happens at runtime.

  Tuples:
    - check 'if it is a tuple with given size' (at depth)
    - check types of elements (at depth - 1)

  List:
    - check 'if it is a list'
    - check whether it is a proper list by iterating to the end (at depth - 1)
    - check types of elements (at depth - 2)

  Maps:
    - check 'if it is a map' (at depth)
    - check for precence and types of all (expected) keys (at depth - 1)
    - check types of values (at depth - 2)

  """
  defstruct [
    enabled: true,
    depth: :infinity
  ]

  def new() do
    %__MODULE__{}
  end

  def new(enum) do
    struct(new(), enum)
  end
end
