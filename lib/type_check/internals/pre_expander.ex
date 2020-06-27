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
        quote location: :keep do
          TypeCheck.Builtin.literal(unquote(value))
        end
      x when is_integer(x) or is_float(x) or is_atom(x) or is_bitstring(x) or is_list(x) ->
        quote location: :keep do
          TypeCheck.Builtin.literal(unquote(x))
        end

      {:|, _, [lhs, rhs]} ->
        quote location: :keep do
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
  end

  defp rewrite_tuple(tuple_elements, env) do
    rewritten_elements =
      tuple_elements
      |> Enum.map(&rewrite(&1, env))

    quote location: :keep do
      TypeCheck.Builtin.tuple(unquote(rewritten_elements))
    end
  end

  def rewrite_map_and_struct(struct_fields, orig_ast) do
    case struct_fields[:__struct__] do
      Range ->
        quote location: :keep do
          TypeCheck.Builtin.range(unquote(orig_ast))
        end
      nil ->
        # A map with fixed fields
        quote location: :keep do
          TypeCheck.Builtin.fixed_map(unquote(orig_ast))
        end
      other ->
        # Unhandled expanded structs
        quote location: :keep do
          # TODO we might want to treat maps/structs differently
          # than literals in certain cases
          # like allowing types to be specified for the keys?
          TypeCheck.Builtin.literal(unquote(orig_ast))
        end
    end
  end
end
