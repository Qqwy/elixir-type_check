defmodule TypeCheck.Internals.ToTypespec do
  def full_rewrite(ast, env) do
    Macro.prewalk(ast, &rewrite(&1, env))
  end

  # TODO incorporate %Macro.Env{}.functions
  # to check whether TypeCheck.Builtin was imported
  # to see what kind of rewrite we should do.
  def rewrite(ast, env) do
    case Macro.expand(ast, env) do
      {:lazy_explicit, _, [module, name, arguments]} ->
        # Removes 'lazy' from typespec.
        quote do
          unquote(module).unquote(name)(unquote_splicing(arguments))
        end

      {:when, _, [type, _]} ->
        # Hide `when` that might contain code from the typespec
        type

      {:guarded_by, _, [type, _]} ->
        # Hide `when` that might contain code from the typespec
        type

      {:"::", _, [_name, type_ast]} ->
        # Hide inner named types from the typespec.
        type_ast

      {:named_type, _, [_name, type_ast]} ->
        # Hide inner named types from the typespec.
        type_ast

      {:one_of, _, types} ->
        Enum.reduce(types, fn type, snippet ->
          quote do
            unquote(snippet) | unquote(type)
          end
        end)

      {:fixed_tuple, meta, [elem_types]} ->
        {:{}, meta, elem_types}

      {:tuple, meta, [size]} ->
        elems =
          0..size
          |> Enum.map(fn _ ->
            quote do
              any()
            end
          end)

        {:{}, meta, elems}

      {:fixed_list, _meta, [elem_types]} ->
        elem_types

      {:range, _meta, [lower, higher]} ->
        quote do
          unquote(lower)..unquote(higher)
        end

      {:range, _meta, [range]} ->
        quote do
          unquote(range)
        end

      {:literal, _, [elem_type]} ->
        # TODO range
        quote do
          unquote(elem_type)
        end

      {:fixed_map, _, [keywords]} ->
        snippets =
          keywords
          |> Enum.map(fn {key, value} ->
            quote do
              {required(unquote(key)), unquote(value)}
            end
          end)

        quote do
          %{unquote_splicing(snippets)}
        end

      {:map, _, [key_type, value_type]} ->
        quote do
          %{optional(unquote(key_type)) => unquote(value_type)}
        end

      other ->
        other
    end
  end
end
