defmodule TypeCheck.TypeError do
  @moduledoc """
  Exception to be returned or raised when a value is not of the expected type.

  This exception has two fields:

  - `:raw`, which will contain the problem tuple of the type check failure.
  - `:message`, which will contain a the humanly-readable representation of the raw problem_tuple

  `:message` is constructed from `:raw` using the TypeCheck.TypeError.DefaultFormatter.
  (TODO at some point this might be configured to use your custom formatter instead)

  """
  defexception [:message, :raw, :location]

  @type t() :: %__MODULE__{message: String.t(), raw: problem_tuple(), location: location()}

  @typedoc """
  Any built-in TypeCheck struct (c.f. `TypeCheck.Builtin.*`), whose check(s) failed.
  """
  @type type_checked_against :: TypeCheck.Type.t()

  @typedoc """
  The name of the particular check. Might be `:no_match` for simple types,
  but for more complex types that have multiple checks, it disambugates between them.

  For instance, for `TypeCheck.Builtin.List` we have `:not_a_list`, `:different_length`, and `:element_error`.
  """
  @type check_name :: atom()

  @type location :: [] | [file: binary(), line: non_neg_integer()]

  @typedoc """
  An extra map with any information related to the check that failed.

  For instance, if the check was a compound check, will contain the field `problem:` with the child problem_tuple
  as well as `:index` or `:key` etc. to indicate _where_ in the compound structure the check failed.
  """
  @type extra_information :: %{optional(atom) => any()}

  @typedoc """
  The value that was passed in which failed the check.

  It is included for the easy creation of `value did not match y`-style messages.
  """
  @type problematic_value :: any()
  @typedoc """
  A problem_tuple contains all information about a failed type check.

  c.f. TypeCheck.TypeError.Formatter.problem_tuple for a more precise definition
  """
  @type problem_tuple ::
          {type_checked_against(), check_name(), extra_information(), problematic_value()}

  @impl true
  # @spec exception({problem_tuple(), any()} | problem_tuple()) :: t()
  def exception({problem_tuple, location}) do
    message = TypeCheck.TypeError.DefaultFormatter.format(problem_tuple, location)

    %__MODULE__{message: message, raw: problem_tuple, location: location}
  end

  def exception(problem_tuple) do
    case problem_tuple do
      {_, _, _, _} ->
        exception({problem_tuple, []})
      other ->
        raise "Cannot make a TypeCheck.TypeError exception from #{inspect(other)}"
    end
  end
end
