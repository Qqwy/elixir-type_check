defmodule TypeCheck.Internals.ToTypespec do
  def full_rewrite(ast, env) do
    Macro.postwalk(ast, &rewrite(&1, env))
  end

  # TODO incorporate %Macro.Env{}.functions
  # to check whether TypeCheck.Builtin was imported
  # to see what kind of rewrite we should do.
  def rewrite(ast, env) do
    builtin_imports = env.functions[TypeCheck.Builtin] || []
    case Macro.expand(ast, env) do
      ast = {:lazy_explicit, _, [module, name, arguments]} ->
        if {:lazy_explicit, 3} in builtin_imports do
          # Removes 'lazy' from typespec.
          quote do
            unquote(module).unquote(name)(unquote_splicing(arguments))
          end
        else
          ast
        end

      {:when, _, [type, _]} ->
        # Hide `when` that might contain code from the typespec
        type

      ast = {:guarded_by, _, [type, _]} ->
        if {:guarded_by, 2} in builtin_imports do
          # Hide `when` that might contain code from the typespec
          type
        else
          ast
        end

      ast = {:wrap_with_gen, _, [type, _]} ->
        if {:wrap_with_gen, 2} in (env.functions[TypeCheck.Type.StreamData] || []) do
          # Hide generator wrapper
          type
        else
          ast
        end

      {:"::", _, [_name, type_ast]} ->
        # Hide inner named types from the typespec.
        type_ast

      ast = {:named_type, _, [_name, type_ast]} ->
        if {:named_type, 2} in builtin_imports do
          # Hide inner named types from the typespec.
          type_ast
        else
          ast
        end

      ast = {:one_of, _, [types]} ->
        if {:one_of, 1} in builtin_imports do
        Enum.reduce(types, fn type, snippet ->
          quote do
            unquote(snippet) | unquote(type)
          end
        end)
        else
          ast
        end

      ast = {:fixed_tuple, meta, [elem_types]} ->
        if {:fixed_tuple, 1} in builtin_imports do
          {:{}, meta, elem_types}
        else
          ast
        end

      ast = {:tuple, meta, [size]} ->
        if {:tuple, 1} in builtin_imports do
        elems =
          0..size
          |> Enum.map(fn _ ->
            quote do
              any()
            end
          end)

        {:{}, meta, elems}
        else
          ast
        end

      ast = {:fixed_list, _meta, [elem_types]} ->
        if {:fixed_list, 1} in builtin_imports do
          elem_types
        else
          ast
        end

      {:range, _meta, [lower, higher]} ->
        quote do
          unquote(lower)..unquote(higher)
        end

      {:range, _meta, [range]} ->
        quote do
          unquote(range)
        end

      {:literal, _, [elem_type]} ->
        if is_binary(elem_type) do
          quote do
            binary()
          end
        else
          quote do
            unquote(elem_type)
          end
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

      # Relax these types that Elixir's builtin typespecs does not accept
      binary when is_binary(binary) ->
        quote do
          binary()
        end
      float when is_float(float) ->
        quote do
          float()
        end

      other ->
        other
    end
  end
end
