defmodule TypeCheck.TypeError.DefaultFormatter do
  @behaviour TypeCheck.TypeError.Formatter

  def format_wrap(value = {_, _, _, input}) do
    """
    #{inspect(input)} fails to typecheck.

    #{format(value)}
    """
  end

  def format({TypeCheck.Builtin.Integer, :not_an_integer, _, val}) do
    "#{inspect(val)} is not an integer."
  end

  def format({TypeCheck.Builtin.Float, :not_a_float, _, val}) do
    "#{inspect(val)} is not a float."
  end

  def format({TypeCheck.Builtin.List, :not_a_list, _, val}) do
    "#{inspect(val)} is not a list."
  end

  def format({TypeCheck.Builtin.List, :element_error, %{problem: problem, index: index, element_type: element_type}, val}) do
    child_problem = """
    at index #{index}:
    #{indent(format(problem))}
    """

    """
    #{inspect(val)} is not a list(#{TypeCheck.Inspect.inspect_binary(element_type)}). Reason:
    #{indent(child_problem)}
    """
  end

  def format({TypeCheck.Builtin.Literal, :not_same_value, %{value: expected_value}, val}) do
    "#{inspect(val)} is not the same value as #{inspect(expected_value)}."
  end

  defp indent(str) do
    String.replace("  " <> str, "\n", "\n  ")
  end
end
