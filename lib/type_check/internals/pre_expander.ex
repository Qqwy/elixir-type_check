defmodule TypeCheck.Internals.PreExpander do
  @moduledoc false
  # Rewrites a typecheck-AST
  # to replace all Kernel.SpecialForms
  # with alternatives that are not 'special'
  # that e.g. are function calls to functions in `TypeCheck.Builtin`.
  def rewrite(ast, env) do
    case Macro.expand(ast, env) do
      {:literal, _, [value]} ->
        # Do not expand internals of `literal`.
        # Even if it contains fancy syntax
        # like ranges
        quote do
          TypeCheck.Builtin.literal(value)
        end
      x when is_integer(x) or is_float(x) or is_atom(x) or is_bitstring(x) or is_list(x) ->
        quote do
          TypeCheck.Builtin.literal(unquote(x))
        end

      {:|, _, [lhs, rhs]} ->
        quote do
          TypeCheck.Builtin.either(unquote(rewrite(lhs, env)), unquote(rewrite(rhs, env)))
        end
      ast = {:%{}, _, fields} ->
        rewrite_map_and_struct(fields, ast)
      {:{}, _, elements} ->
        rewrite_tuple(elements, env)
      {left, right} ->
        rewrite_tuple([left, right], env)

      # Fallback:
      other ->
        other
  end

  defp rewrite_tuple(tuple_elements, env) do
    rewritten_elements =
      elements
      |> Enum.map(&rewrite(&1, env))

    quote do
      TypeCheck.Builtin.tuple(unquote(rewritten_elements))
    end
  end

  def rewrite_map_and_struct(struct_fields, orig_ast) do
    case struct_fields[:__struct__] do
      Range ->
        quote do
          TypeCheck.Builtin.range(lower, higher)
        end
      other ->
        # Unhandled maps and structs
        quote do
          # TODO we might want to treat maps/structs differently
          # than literals in certain cases
          # like allowing types to be specified for the keys?
          TypeCheck.Builtin.literal(ast)
        end
    end
  end
end
