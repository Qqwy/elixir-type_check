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
      x when is_integer(x) or is_float(x) or is_atom(x) or is_bitstring(x) ->
        quote location: :keep do
          TypeCheck.Builtin.literal(unquote(x))
        end
      list when is_list(list) ->
        rewritten_values =
          list
          |> Enum.map(&rewrite(&1, env))
        quote location: :keep do
          TypeCheck.Builtin.fixed_list(unquote(rewritten_values))
        end
      {:|, _, [lhs, rhs]} ->
        quote location: :keep do
          TypeCheck.Builtin.either(unquote(rewrite(lhs, env)), unquote(rewrite(rhs, env)))
        end
      ast = {:%{}, _, fields} ->
        rewrite_map_and_struct(fields, ast, env)
      {:%, _, [struct_name, {:%{}, _, fields}]} ->
        rewrite_struct(struct_name, fields, env)
      {:"::", _, [{name, _, atom}, type_ast]} when is_atom(atom) ->
        quote location: :keep do
          TypeCheck.Builtin.named_type(unquote(name), unquote(rewrite(type_ast, env)))
        end
      {:{}, _, elements} ->
        rewrite_tuple(elements, env)
      {left, right} ->
        rewrite_tuple([left, right], env)

      {other_fun, meta, args} when is_list(args) ->
        # Make sure arguments of any function are expanded
        {other_fun, meta, Enum.map(args, &rewrite(&1, env))}
      other ->
        # Fallback
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

  defp rewrite_map_and_struct(struct_fields, orig_ast, env) do
    case struct_fields[:__struct__] do
      Range ->
        quote location: :keep do
          TypeCheck.Builtin.range(unquote(orig_ast))
        end
      nil ->
        # A map with fixed fields
        field_types =
          Enum.map(struct_fields, fn {key, value_type} -> {key, rewrite(value_type, env)} end)

        quote location: :keep do
          # TODO correctly recurse over keys
          TypeCheck.Builtin.fixed_map(unquote(field_types))
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

  defp rewrite_struct(struct_name, fields, env) do
    field_types =
      Enum.map(fields, fn {key, value_type} -> {key, rewrite(value_type, env)} end)
    # TODO wrap in struct-checker
    quote do
      TypeCheck.Builtin.fixed_map([__struct__: TypeCheck.Builtin.literal(unquote(struct_name))] ++ unquote(field_types))
    end
  end
end
