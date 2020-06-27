defmodule TypeCheck.TypeError.DefaultFormatter do
  @behaviour TypeCheck.TypeError.Formatter

  def format_wrap(value = {_, _, _, input}) do
    """
    #{format(value)}
    """
    # |> String.trim_trailing("\n")
  end

  def format({%TypeCheck.Builtin.Integer{}, :not_an_integer, _, val}) do
    "`#{inspect(val)}` is not an integer."
  end

  def format({s = %TypeCheck.Builtin.Range{}, :not_an_integer, _, val}) do
    compound_check(val, s, "`#{inspect(val)}` is not an integer.")
  end

  def format({%TypeCheck.Builtin.Atom{}, :not_an_atom, _, val}) do
    "`#{inspect(val)}` is not an atom."
  end

  def format({s = %TypeCheck.Builtin.Range{range: range}, :not_in_range, _, val}) do
    compound_check(val, s, "`#{inspect(val)}` falls outside the range #{inspect(range)}.")
  end

  def format({%TypeCheck.Builtin.Float{}, :not_a_float, _, val}) do
    "`#{inspect(val)}` is not a float."
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
