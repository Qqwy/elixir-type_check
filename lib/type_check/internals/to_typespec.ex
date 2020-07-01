defmodule TypeCheck.Internals.ToTypespec do
  # defmacro define_all() do
  #   define_extra_builtin_types(__CALLER__, [], :opaque)
  # end

  # def define_extra_builtin_types(caller_env, except, kind \\ :typep) do
  #   extra_builtin_types = %{
  #     {:literal, 1} => quote do literal(t) :: t end,
  #     {:tuple, 1} => quote do tuple(_integer_size) :: tuple() end, # Untypeable in Elixir Typespecs
  #     {:tuple_of, 1} => quote do tuple_of(_list_of_element_types) :: tuple() end # Untypeable in Elixir Typespecs
  #   }
  #   extra_builtin_type_signatures = extra_builtin_types |> Map.keys
  #   non_overridden_type_signatures = extra_builtin_type_signatures -- except

  #   extra_typedefs =
  #     non_overridden_type_signatures
  #     |> Enum.map(fn {name, arity} ->
  #       case kind do
  #         :opaque ->
  #           quote generated: true do
  #             @opaque unquote(extra_builtin_types[{name, arity}])
  #           end
  #         :typep ->
  #           quote generated: true do
  #             @typep unquote(extra_builtin_types[{name, arity}])
  #           end
  #       end
  #     end)

  #     quote generated: true do
  #       unquote_splicing(extra_typedefs)
  #     end
  # end

  def full_rewrite(ast, env) do
    Macro.prewalk(ast, &rewrite(&1, env))
  end

  def rewrite(ast, env) do
    case Macro.expand(ast, env) do
      {:when, _, [type, _]} ->
        # Hide `when` that might contain code from the typespec
        type
      {:guarded_by, _, [type, _]} ->
        # Hide `when` that might contain code from the typespec
        type
      {:"::", _, [_name, type_ast]} ->
        # Hide inner named types from the typespec.
        type_ast
      {:"named_type", _, [_name, type_ast]} ->
        # Hide inner named types from the typespec.
        type_ast
      {:either, _, [left, right]} ->
        quote do
          left | right
        end
      {:tuple_of, meta, [elem_types]} ->
        {:{}, meta, elem_types}
      {:tuple, meta, [size]} ->
        elems = 0..size |> Enum.map(fn _ -> quote do any() end end)
        {:{}, meta, elems}
      {:fixed_list, meta, [elem_types]} ->
        elem_types
      {:range, meta, [lower, higher]} ->
        quote do
          unquote(lower)..unquote(higher)
        end
      {:range, meta, [range]} ->
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
            quote do {required(unquote(key)), unquote(value)} end
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
