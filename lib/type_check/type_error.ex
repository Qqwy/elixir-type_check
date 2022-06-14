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

  def exception({problem_tuple, location}) do
    message = TypeCheck.TypeError.DefaultFormatter.format(problem_tuple, location)

    %__MODULE__{message: message, raw: problem_tuple, location: location}
  end

  def exception(problem_tuple) do
    exception({problem_tuple, []})
  end

  @simple_problems ~w[no_match not_same_value not_a_map not_a_list missing_keys superfluous_keys different_length different_size not_an_integer not_in_range wrong_size]a

  def hydrate_problem_tuple(s = %TypeCheck.Type.StreamData{}, problem_tuple) do
    hydrate_problem_tuple(s.type, problem_tuple)
  end

  def hydrate_problem_tuple(s, problem_tuple) do
    case problem_tuple do
      {simple, meta, param} when simple in @simple_problems -> {s, simple, meta, param}
      {:value_error, meta, param} ->
        # TODO CompoundFixedMap
        s2 = s.keypairs[meta.key]
        meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
        {s, :value_error, meta2, param}
      {:key_error, meta, param} ->
        s2 = meta.key
        meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
        {s, :key_error, meta2, param}
      {:element_error, meta, param} -> # Handles both fixed_list and fixed_tuple
        case s do
          %TypeCheck.Builtin.List{} ->
            s2 = s.element_type
            meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
            {s, :element_error, meta2, param}
          %TypeCheck.Builtin.MaybeImproperList{} ->
            s2 = s.element_type
            meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
            {s, :element_error, meta2, param}
          %TypeCheck.Builtin.FixedList{} ->
            s2 = Enum.at(s.element_types, meta.index)
            meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
            {s, :element_error, meta2, param}
          %TypeCheck.Builtin.FixedTuple{} ->
            s2 = Enum.at(s.element_types, meta.index)
            meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
            {s, :element_error, meta2, param}
        end
      {:terminator_error, meta, param} ->
        s2 = s.terminator_type
        meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
        {:terminator_error, meta2, param}
      {:named_type, meta, param} ->
        s2 = s.type
        meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
        {:named_type, meta2, param}
      {:all_failed, meta, param} ->
        hydrated_problems =
          Enum.zip(s.choices, meta.problems)
          |> Enum.map(fn s2, problem ->
            hydrate_problem_tuple(s2, problem)
          end)
        meta2 = put_in(meta.problems, hydrated_problems)
        {:all_failed, meta2, param}
      {:return_error, meta, param} ->
        s2 = s.return_type
        meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
        {s, :return_error, meta2, param}
      {:param_error, meta, param} ->
        s2 = Enum.at(s.param_types, meta.index)
        meta2 = update_in(meta.problem, &hydrate_problem_tuple(s2, &1))
        {s, :param_error, meta2, param}
      other ->
        IO.warn("TODO: #{inspect({s, problem_tuple})}")
        other
    end
  end
end
