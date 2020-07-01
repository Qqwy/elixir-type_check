defmodule TypeCheck.TypeError.DefaultFormatter do
  @behaviour TypeCheck.TypeError.Formatter

  @doc """
  Transforms a `problem_tuple` into a humanly-readable explanation string.

  C.f. `TypeCheck.TypeError.Formatter` for more information about problem tuples.
  """
  @spec format(TypeCheck.TypeError.Formatter.problem_tuple) :: String.t()
  def format(problem_tuple)

  def format({%TypeCheck.Builtin.Atom{}, :no_match, _, val}) do
    "`#{inspect(val)}` is not an atom."
  end

  def format({%TypeCheck.Builtin.Binary{}, :no_match, _, val}) do
    "`#{inspect(val)}` is not a binary."
  end

  def format({%TypeCheck.Builtin.Bitstring{}, :no_match, _, val}) do
    "`#{inspect(val)}` is not a bitstring."
  end

  def format({%TypeCheck.Builtin.Boolean{}, :no_match, _, val}) do
    "`#{inspect(val)}` is not a boolean."
  end

  def format({s = %TypeCheck.Builtin.FixedList{}, :not_a_list, _, val}) do
    problem = "`#{inspect(val)}` is not a list."
    compound_check(val, s, problem)
  end

  def format({s = %TypeCheck.Builtin.FixedList{}, :different_length, %{expected_length: expected_length}, val}) do
    problem = "`#{inspect(val)}` has #{length(val)} elements rather than #{expected_length}."
    compound_check(val, s, problem)
  end

  def format({s = %TypeCheck.Builtin.FixedList{}, :element_error, %{problem: problem, index: index}, val}) do
    compound_check(val, s, "at index #{index}:\n", format(problem))
  end

  def format({s = %TypeCheck.Builtin.FixedMap{}, :not_a_map, _, val}) do
    problem = "`#{inspect(val)}` is not a map."
    compound_check(val, s, problem)
  end

  def format({s = %TypeCheck.Builtin.FixedMap{}, :missing_keys, %{keys: keys}, val}) do
    keys_str =
      keys
      |> Enum.map(&inspect/1)
      |> Enum.join(", ")
    problem = "`#{inspect(val)}` is missing the following required key(s): `#{keys_str}`."
    compound_check(val, s, problem)
  end

  def format({s = %TypeCheck.Builtin.FixedMap{}, :value_error, %{problem: problem, key: key}, val}) do
    compound_check(val, s, "under key `#{inspect(key)}`:\n", format(problem))
  end

  def format({%TypeCheck.Builtin.Float{}, :no_match, _, val}) do
    "`#{inspect(val)}` is not a float."
  end

  def format({%TypeCheck.Builtin.Function{}, :no_match, _, val}) do
    "`#{inspect(val)}` is not a function."
  end

  def format({s = %TypeCheck.Builtin.Guarded{}, :type_failed, %{problem: problem}, val}) do
    compound_check(val, s, format(problem))
  end

  def format({s = %TypeCheck.Builtin.Guarded{}, :guard_failed, %{bindings: bindings}, val}) do
    problem = """
    `#{Macro.to_string(s.guard)}` evaluated to false or nil.
    bound values: #{inspect(bindings)}
    """
    compound_check(val, s, "type guard:\n", problem)
  end

  def format({%TypeCheck.Builtin.Integer{}, :no_match, _, val}) do
    "`#{inspect(val)}` is not an integer."
  end

  def format({s = %TypeCheck.Builtin.List{}, :not_a_list, _, val}) do
    compound_check(val, s, "`#{inspect(val)}` is not a list.")
  end

  def format({s = %TypeCheck.Builtin.List{}, :element_error, %{problem: problem, index: index}, val}) do
    compound_check(val, s, "at index #{index}:\n", format(problem))
  end

  def format({%TypeCheck.Builtin.Literal{value: expected_value}, :not_same_value, %{}, val}) do
    "`#{inspect(val)}` is not the same value as `#{inspect(expected_value)}`."
  end

  # TODO Map

  def format({s = %TypeCheck.Builtin.NamedType{}, :named_type, %{problem: problem}, val}) do
    compound_check(val, s, format(problem))
  end

  def format({%TypeCheck.Builtin.Number{}, :no_match, _, val}) do
    "`#{inspect(val)}` is not a number."
  end

  def format({s = %TypeCheck.Builtin.OneOf{}, :all_failed, %{problems: problems}, val}) do
    message =
      problems
      |> Enum.with_index()
      |> Enum.map(fn {problem, index} ->
    """
    #{index})
    #{indent(format(problem))}
    """
    end)
    |> Enum.join("\n")
      compound_check(val, s, "all possibilities failed:\n", message)
  end

  def format({s = %TypeCheck.Builtin.Range{}, :not_an_integer, _, val}) do
    compound_check(val, s, "`#{inspect(val)}` is not an integer.")
  end

  def format({s = %TypeCheck.Builtin.Range{range: range}, :not_in_range, _, val}) do
    compound_check(val, s, "`#{inspect(val)}` falls outside the range #{inspect(range)}.")
  end

  def format({s = %TypeCheck.Builtin.Tuple{}, :not_a_tuple, _, val}) do
    problem = "`#{inspect(val)}` is not a tuple."
    compound_check(val, s, problem)
  end

  def format({s = %TypeCheck.Builtin.Tuple{}, :different_size, %{expected_size: expected_size}, val}) do
    problem = "`#{inspect(val)}` has #{tuple_size(val)} elements rather than #{expected_size}."
    compound_check(val, s, problem)
  end

  def format({s = %TypeCheck.Builtin.Tuple{}, :element_error, %{problem: problem, index: index}, val}) do
    compound_check(val, s, "at index #{index}:\n", format(problem))
  end

  def format({s = %TypeCheck.Spec{}, :param_error, %{index: index, problem: problem}, val}) do
    # compound_check(val, s, "at parameter no. #{index + 1}:\n", format(problem))
    arguments = val |> Enum.map(&inspect/1) |> Enum.join(", ")
    call = "#{s.name}(#{arguments})"
    """
    The call `#{call}` does not adhere to spec `#{TypeCheck.Inspect.inspect_binary(s)}`. Reason:
      parameter no. #{index + 1}:
    #{indent(indent(format(problem)))}
    """
  end

  def format({s = %TypeCheck.Spec{}, :return_error, %{problem: problem, arguments: arguments}, _val}) do
    arguments_str = arguments |> Enum.map(&inspect/1) |> Enum.join(", ")
    call = "#{s.name}(#{arguments_str})"
    """
    The result of calling `#{call}` does not adhere to spec `#{TypeCheck.Inspect.inspect_binary(s)}`. Reason:
      Returned result:
    #{indent(indent(format(problem)))}
    """
  end

  defp compound_check(val, s, child_prefix \\ nil, child_problem) do
    child_str =
    if child_prefix do
      indent(child_prefix <> indent(child_problem))
    else
      indent(child_problem)
    end

    """
    `#{inspect(val)}` does not check against `#{TypeCheck.Inspect.inspect_binary(s)}`. Reason:
    #{child_str}
    """
  end

  defp indent(str) do
    String.replace("  " <> str, "\n", "\n  ")
  end
end
