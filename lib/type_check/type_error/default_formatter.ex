defmodule TypeCheck.TypeError.DefaultFormatter do
  @behaviour TypeCheck.TypeError.Formatter

  def format(problem_tuple, location \\ []) do
    res =
      do_format(problem_tuple)
      |> indent() # Ensure we start with four spaces, which multi-line exception pretty-printing expects
      |> indent()

    location_string(location) <> res
    |> String.trim()
  end

  defp location_string([]), do: ""
  defp location_string(location) do
    raw_file = location[:file]
    line = location[:line]

    file = String.replace_prefix(raw_file, File.cwd! <> "/", "")
    "At #{file}:#{line}:\n"
  end

  @doc """
  Transforms a `problem_tuple` into a humanly-readable explanation string.

  C.f. `TypeCheck.TypeError.Formatter` for more information about problem tuples.
  """
  @spec do_format(TypeCheck.TypeError.Formatter.problem_tuple()) :: String.t()
  def do_format(problem_tuple)

  def do_format({%TypeCheck.Builtin.Atom{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not an atom."
  end

  def do_format({%TypeCheck.Builtin.Binary{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a binary."
  end

  def do_format({%TypeCheck.Builtin.Bitstring{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a bitstring."
  end

  def do_format({%TypeCheck.Builtin.Boolean{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a boolean."
  end

  def do_format({s = %TypeCheck.Builtin.FixedList{}, :not_a_list, _, val}) do
    problem = "`#{inspect(val, inspect_value_opts())}` is not a list."
    compound_check(val, s, problem)
  end

  def do_format(
        {s = %TypeCheck.Builtin.FixedList{}, :different_length,
         %{expected_length: expected_length}, val}
      ) do
    problem = "`#{inspect(val, inspect_value_opts())}` has #{length(val)} elements rather than #{expected_length}."
    compound_check(val, s, problem)
  end

  def do_format(
        {s = %TypeCheck.Builtin.FixedList{}, :element_error, %{problem: problem, index: index},
         val}
      ) do
    compound_check(val, s, "at index #{index}:\n", do_format(problem))
  end

  def do_format({s = %TypeCheck.Builtin.FixedMap{}, :not_a_map, _, val}) do
    problem = "`#{inspect(val, inspect_value_opts())}` is not a map."
    compound_check(val, s, problem)
  end

  def do_format({s = %TypeCheck.Builtin.FixedMap{}, :missing_keys, %{keys: keys}, val}) do
    keys_str =
      keys
      |> Enum.map(&inspect/1)
      |> Enum.join(", ")

    problem = "`#{inspect(val, inspect_value_opts())}` is missing the following required key(s): `#{keys_str}`."
    compound_check(val, s, problem)
  end

  def do_format(
        {s = %TypeCheck.Builtin.FixedMap{}, :value_error, %{problem: problem, key: key}, val}
      ) do
    compound_check(val, s, "under key `#{inspect(key, inspect_type_opts())}`:\n", do_format(problem))
  end

  def do_format({%TypeCheck.Builtin.Float{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a float."
  end

  def do_format({%TypeCheck.Builtin.Function{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a function."
  end

  def do_format({s = %TypeCheck.Builtin.Guarded{}, :type_failed, %{problem: problem}, val}) do
    compound_check(val, s, do_format(problem))
  end

  def do_format({s = %TypeCheck.Builtin.Guarded{}, :guard_failed, %{bindings: bindings}, val}) do
    guard_str = Inspect.Algebra.format(Inspect.Algebra.color(Macro.to_string(s.guard), :builtin_type, struct(Inspect.Opts, inspect_type_opts())), 80)

    problem = """
    `#{guard_str}` evaluated to false or nil.
    bound values: #{inspect(bindings, inspect_type_opts())}
    """

    compound_check(val, s, "type guard:\n", problem)
  end

  def do_format({%TypeCheck.Builtin.Integer{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not an integer."
  end

  def do_format({%TypeCheck.Builtin.PosInteger{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a positive integer."
  end

  def do_format({%TypeCheck.Builtin.NegInteger{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a negative integer."
  end

  def do_format({%TypeCheck.Builtin.NonNegInteger{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a non-negative integer."
  end

  def do_format({s = %TypeCheck.Builtin.List{}, :not_a_list, _, val}) do
    compound_check(val, s, "`#{inspect(val, inspect_value_opts())}` is not a list.")
  end

  def do_format(
        {s = %TypeCheck.Builtin.List{}, :element_error, %{problem: problem, index: index}, val}
      ) do
    compound_check(val, s, "at index #{index}:\n", do_format(problem))
  end

  def do_format({%TypeCheck.Builtin.Literal{value: expected_value}, :not_same_value, %{}, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not the same value as `#{inspect(expected_value, inspect_type_opts())}`."
  end

  def do_format({s = %TypeCheck.Builtin.Map{}, :not_a_map, _, val}) do
    compound_check(val, s, "`#{inspect(val, inspect_value_opts())}` is not a map.")
  end

  def do_format({s = %TypeCheck.Builtin.Map{}, :key_error, %{problem: problem}, val}) do
    compound_check(val, s, "key error:\n", do_format(problem))
  end

  def do_format({s = %TypeCheck.Builtin.Map{}, :value_error, %{problem: problem, key: key}, val}) do
    compound_check(val, s, "under key `#{inspect(key, inspect_type_opts())}`:\n", do_format(problem))
  end

  def do_format({s = %TypeCheck.Builtin.NamedType{}, :named_type, %{problem: problem}, val}) do
    child_str =
      indent(do_format(problem))

    """
    `#{inspect(val, inspect_value_opts())}` does not match the definition of the named type `#{Inspect.Algebra.format(Inspect.Algebra.color(to_string(s.name), :named_type, struct(Inspect.Opts, inspect_type_opts())), 80)}`
    which is: `#{TypeCheck.Inspect.inspect_binary(s, [show_long_named_type: true] ++ inspect_type_opts())}`. Reason:
    #{child_str}
    """

    # compound_check(val, s, do_format(problem))
  end

  def do_format({%TypeCheck.Builtin.None{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` does not match `none()` (no value matches `none()`)."
  end

  def do_format({%TypeCheck.Builtin.Number{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a number."
  end

  def do_format({s = %TypeCheck.Builtin.OneOf{}, :all_failed, %{problems: problems}, val}) do
    message =
      problems
      |> Enum.with_index()
      |> Enum.map(fn {problem, index} ->
        """
        #{index})
        #{indent(do_format(problem))}
        """
      end)
      |> Enum.join("\n")

    compound_check(val, s, "all possibilities failed:\n", message)
  end

  def do_format({%TypeCheck.Builtin.PID{}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` is not a pid."
  end

  def do_format({s = %TypeCheck.Builtin.Range{}, :not_an_integer, _, val}) do
    compound_check(val, s, "`#{inspect(val, inspect_value_opts())}` is not an integer.")
  end

  def do_format({s = %TypeCheck.Builtin.Range{range: range}, :not_in_range, _, val}) do
    compound_check(val, s, "`#{inspect(val, inspect_value_opts())}` falls outside the range #{inspect(range, inspect_type_opts())}.")
  end

  def do_format({s = %TypeCheck.Builtin.FixedTuple{}, :not_a_tuple, _, val}) do
    problem = "`#{inspect(val, inspect_value_opts())}` is not a tuple."
    compound_check(val, s, problem)
  end

  def do_format(
        {s = %TypeCheck.Builtin.FixedTuple{}, :different_size, %{expected_size: expected_size},
         val}
      ) do
    problem = "`#{inspect(val, inspect_value_opts())}` has #{tuple_size(val)} elements rather than #{expected_size}."
    compound_check(val, s, problem)
  end

  def do_format(
        {s = %TypeCheck.Builtin.FixedTuple{}, :element_error, %{problem: problem, index: index},
         val}
      ) do
    compound_check(val, s, "at index #{index}:\n", do_format(problem))
  end

  def do_format({s = %TypeCheck.Builtin.Tuple{}, :no_match, _, val}) do
    problem = "`#{inspect(val, inspect_value_opts())}` is not a tuple."
    compound_check(val, s, problem)
  end

  def do_format({%TypeCheck.Builtin.ImplementsProtocol{protocol: protocol_name}, :no_match, _, val}) do
    "`#{inspect(val, inspect_value_opts())}` does not implement the protocol `#{protocol_name}`"
  end

  def do_format({s = %TypeCheck.Spec{}, :param_error, %{index: index, problem: problem}, val}) do
    # compound_check(val, s, "at parameter no. #{index + 1}:\n", do_format(problem))
    function_with_arity = IO.ANSI.format_fragment([:white, "#{s.name}/#{Enum.count(val)}", :red])
    param_spec = s.param_types |> Enum.at(index) |> TypeCheck.Inspect.inspect_binary(inspect_type_opts())
    arguments = val |> Enum.map(&inspect/1) |> Enum.join(", ")
    call = IO.ANSI.format_fragment([:white, "#{s.name}(#{arguments})", :red])

    value = Enum.at(val, index)
    value_str = inspect(value, inspect_value_opts())

    """
    The call to `#{function_with_arity}` failed,
    because parameter no. #{index + 1} does not adhere to the spec `#{param_spec}`.
    Rather, its value is: `#{value_str}`.
    Details:
      The call `#{call}`
      does not adhere to spec `#{TypeCheck.Inspect.inspect_binary(s, inspect_type_opts())}`. Reason:
        parameter no. #{index + 1}:
    #{indent(indent(indent(do_format(problem))))}
    """
  end

  def do_format(
        {s = %TypeCheck.Spec{}, :return_error, %{problem: problem, arguments: arguments}, val}
      ) do
    function_with_arity = IO.ANSI.format_fragment([:white, "#{s.name}/#{Enum.count(arguments)}", :red])
    result_spec = s.return_type |> TypeCheck.Inspect.inspect_binary(inspect_type_opts())
    arguments_str = arguments |> Enum.map(fn val -> inspect(val, inspect_type_opts()) end) |> Enum.join(", ")
    call = IO.ANSI.format_fragment([:white, "#{s.name}(#{arguments_str})", :red])

    val_str = inspect(val, inspect_value_opts())

    """
    The call to `#{function_with_arity}` failed,
    because the returned result does not adhere to the spec `#{result_spec}`.
    Rather, its value is: `#{val_str}`.
    Details:
      The result of calling `#{call}`
      does not adhere to spec `#{TypeCheck.Inspect.inspect_binary(s, inspect_type_opts())}`. Reason:
        Returned result:
    #{indent(indent(indent(do_format(problem))))}
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
    `#{inspect(val, inspect_value_opts())}` does not check against `#{TypeCheck.Inspect.inspect_binary(s, inspect_type_opts())}`. Reason:
    #{child_str}
    """
  end

  defp indent(str) do
    String.replace("  " <> str, "\n", "\n  ")
  end

  defp inspect_value_opts() do
    # [reset_color: :red, syntax_colors: ([reset: :white] ++ TypeCheck.Inspect.default_colors())]
    if IO.ANSI.enabled? do
      [reset_color: :red, syntax_colors: ([reset: :red] ++ TypeCheck.Inspect.default_colors())]
    else
      []
    end
  end

  defp inspect_type_opts() do
    if IO.ANSI.enabled? do
      [reset_color: :red, syntax_colors: ([reset: :red] ++ TypeCheck.Inspect.default_colors())]
    else
      []
    end
  end
end
