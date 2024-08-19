defmodule TypeCheck.Internals.PreExpander do
  @moduledoc false
  # Rewrites a typecheck-AST
  # to replace all Kernel.SpecialForms
  # with alternatives that are not 'special'
  # that e.g. are function calls to functions in `TypeCheck.Builtin`.
  def rewrite(ast, env, options) do
    builtin_imports = env.functions[TypeCheck.Builtin] || []

    ast
    |> Macro.expand(env)
    |> TypeCheck.Internals.Overrides.rewrite_if_override(Map.get(options, :overrides, []), env)
    |> case do
      ast =
          {{:., outer_meta, [{:__aliases__, alias_meta, module_alias}, unqualified_type]}, meta,
           args} ->
        rewritten_args = Enum.map(args, &rewrite(&1, env, options))

        if Module.concat(module_alias) == env.module do
          {unqualified_type, meta, rewritten_args}
        else
          with [single_atom] <- module_alias,
               {:ok, alias_target} <- TypeCheck.Internals.Helper.fetch_alias(env, single_atom) do
            new_ast =
              {{:., outer_meta, [{:__aliases__, alias_meta, [alias_target]}, unqualified_type]},
               meta, args}

            rewrite(new_ast, env, options)
          else
            _ ->
              put_elem(ast, 2, rewritten_args)
          end
        end

      ast = {:lazy_explicit, meta, args} ->
        if {:lazy_explicit, 3} in builtin_imports do
          ast
        else
          {:lazy_explicit, meta, Enum.map(args, &rewrite(&1, env, options))}
        end

      ast = {:literal, meta, [value]} ->
        # Do not expand internals of `literal`.
        # Even if it contains fancy syntax
        # like ranges
        if {:literal, 1} in builtin_imports do
          ast
        else
          {:literal, meta, [rewrite(value, env, options)]}
        end

      ast = {:tuple, meta, [value]} ->
        if {:tuple, 1} in builtin_imports do
          ast
        else
          {:tuple, meta, [rewrite(value, env, options)]}
        end

      {list_taking_fun, meta, [arg]}
      when is_list(arg) and list_taking_fun in [:fixed_list, :fixed_tuple, :one_of] ->
        if {list_taking_fun, 1} in builtin_imports do
          rewritten_arg =
            arg
            |> Enum.map(&rewrite(&1, env, options))

          quote generated: true, location: :keep do
            TypeCheck.Builtin.unquote(list_taking_fun)(unquote(rewritten_arg))
          end
        else
          {list_taking_fun, meta, [rewrite(arg, env, options)]}
        end

      ast = {:impl, meta, [module]} ->
        # Do not expand arguments to `impl/1` further
        if {:impl, 1} in builtin_imports do
          ast
        else
          {:impl, meta, [rewrite(module, env, options)]}
        end

      ast = {:&, _, _args} ->
        # Do not expand inside captures
        ast

      x when is_integer(x) or is_float(x) or is_atom(x) or is_bitstring(x) ->
        quote generated: true, location: :keep do
          TypeCheck.Builtin.literal(unquote(x))
        end

      [{:->, _, args}] ->
        case args do
          [[{:..., _, module}], return_type] when is_atom(module) or module == [] ->
            quote generated: true, location: :keep do
              TypeCheck.Builtin.function(unquote(rewrite(return_type, env, options)))
            end

          [param_types, return_type] ->
            rewritten_params =
              param_types
              |> Enum.map(&rewrite(&1, env, options))

            quote generated: true, location: :keep do
              TypeCheck.Builtin.function(
                unquote(rewritten_params),
                unquote(rewrite(return_type, env, options))
              )
            end
        end

      list when is_list(list) ->
        case list do
          [] ->
            quote generated: true, location: :keep do
              TypeCheck.Builtin.literal(unquote([]))
            end

          [{:..., _, _}] ->
            quote generated: true, location: :keep do
              TypeCheck.Builtin.nonempty_list()
            end

          [element_type] ->
            rewritten_element_type = rewrite(element_type, env, options)

            quote generated: true, location: :keep do
              TypeCheck.Builtin.list(unquote(rewritten_element_type))
            end

          [element_type, {:..., _, _}] ->
            rewritten_element_type = rewrite(element_type, env, options)

            quote generated: true, location: :keep do
              TypeCheck.Builtin.nonempty_list(unquote(rewritten_element_type))
            end

          other ->
            raise TypeCheck.CompileError, """
            TypeCheck does not support the list literal `#{Macro.to_string(other)}`
            Currently supported are:
            - [] -> empty list
            - [type] -> list(type)
            - [...] -> nonempty_list()
            - [type, ...] -> nonempty_list(type)
            """
        end

      bitstring = {:<<>>, _, args} ->
        case args do
          [] ->
            # Empty bitstring
            quote generated: true, location: :keep do
              TypeCheck.Builtin.literal(unquote(<<>>))
            end

          [{:"::", _, [{:_, _, _}, size]}] when is_integer(size) ->
            # <<_ :: size >>
            quote generated: true, location: :keep do
              TypeCheck.Builtin.sized_bitstring(unquote(size), nil)
            end

          [{:"::", _, [{:_, _, _}, {:*, _, [{:_, _, _}, unit]}]}] when is_integer(unit) ->
            quote generated: true, location: :keep do
              TypeCheck.Builtin.sized_bitstring(0, unquote(unit))
            end

          [
            {:"::", _, [{:_, _, _}, size]},
            {:"::", _, [{:_, _, _}, {:*, _, [{:_, _, _}, unit]}]}
          ] ->
            quote generated: true, location: :keep do
              TypeCheck.Builtin.sized_bitstring(unquote(size), unquote(unit))
            end

          _other ->
            raise TypeCheck.CompileError, """
            TypeCheck does not support the bitstring literal `#{Macro.to_string(bitstring)}`
            Currently supported are:
            - <<>> -> empty bitstring
            - <<_ :: size >> -> a bitstring of exactly `size` bits long
            - <<_ :: _ * unit >> -> a bitstring whose length is divisible by `unit`.
            - <<_ :: size, _ * unit >> -> a bitstring whose (length - `size`) is divisible by `unit`.
            """
        end

      {:|, _, [lhs, rhs]} ->
        quote generated: true, location: :keep do
          TypeCheck.Builtin.one_of(
            unquote(rewrite(lhs, env, options)),
            unquote(rewrite(rhs, env, options))
          )
        end

      ast = {:%{}, _, []} ->
        # Short-circuit for the empty map type.
        quote generated: true, location: :keep do
          TypeCheck.Builtin.literal(unquote(ast))
        end

      ast = {:%{}, _, fields} ->
        rewrite_map_or_struct(fields, ast, env, options)

      {:%, _, [struct_name, {:%{}, _, fields}]} ->
        rewrite_struct(struct_name, fields, env, options)

      {:"::", _, [{name, _, atom}, type_ast]} when is_atom(atom) ->
        quote generated: true, location: :keep do
          TypeCheck.Builtin.named_type(unquote(name), unquote(rewrite(type_ast, env, options)))
        end

      ast = {:when, _, [_type, list]} when is_list(list) ->
        raise TypeCheck.CompileError, """
        Unsupported `when` with keyword arguments in the type description `#{Macro.to_string(ast)}`

        TypeCheck currently does not allow the `function(foo, bar) :: foo | bar when foo: some_type(), bar: other_type()` syntax.
        Instead, define `foo` and `bar` as separate types and refer to those definitions.

        For instance:

        ```
        type foo :: some_type()
        type bar :: other_type()
        spec function(foo, bar) :: foo | bar
        ```
        """

      {:when, _, [type, guard]} ->
        quote generated: true, location: :keep do
          TypeCheck.Builtin.guarded_by(
            unquote(rewrite(type, env, options)),
            unquote(Macro.escape(guard)),
            unquote(env.module)
          )
        end

      {:{}, _, elements} ->
        rewrite_tuple(elements, env, options)

      {left, right} ->
        rewrite_tuple([left, right], env, options)

      orig = {variable, meta, atom} when is_atom(atom) ->
        # Ensures we'll get no pesky warnings when zero-arity types
        # are used without parentheses (just like 'normal' types)
        if variable_refers_to_function?(variable, env) do
          {variable, meta, []}
        else
          orig
        end

      {other_fun, meta, args} when is_list(args) ->
        # Make sure arguments of any function are expanded
        {other_fun, meta, Enum.map(args, &rewrite(&1, env, options))}

      other ->
        # Fallback
        other
    end
  end

  defp variable_refers_to_function?(name, env) do
    definitions =
      env.functions
      |> Enum.flat_map(fn {_module, definitions} -> definitions end)

    {name, 0} in definitions
  end

  defp rewrite_tuple(tuple_elements, env, options) do
    rewritten_elements =
      tuple_elements
      |> Enum.map(&rewrite(&1, env, options))

    quote generated: true, location: :keep do
      TypeCheck.Builtin.fixed_tuple(unquote(rewritten_elements))
    end
  end

  defp rewrite_map_or_struct(struct_fields, orig_ast, env, options) do
    case struct_fields[:__struct__] do
      Range ->
        quote generated: true, location: :keep do
          TypeCheck.Builtin.range(unquote(orig_ast))
        end

      _other ->
        # Any other kind of map or possibly struct type, which might include optional or required keys.
        field_types =
          Enum.reduce(struct_fields, %{fixed: [], required: [], optional: []}, fn
            {{:required, _, [key_type]}, value_type}, acc ->
              req_key = rewrite(key_type, env, options)
              req_value = rewrite(value_type, env, options)

              case req_key do
                # `required(literal(key))`
                {{:., _, [{:__aliases__, _, [:TypeCheck, :Builtin]}, :literal]}, _, [fixed_key]} ->
                  update_in(acc.fixed, fn fixeds -> [{fixed_key, req_value} | fixeds] end)

                _ ->
                  update_in(acc.required, fn requireds -> [{req_key, req_value} | requireds] end)
              end

            {{:optional, _, [key_type]}, value_type}, acc ->
              opt = {rewrite(key_type, env, options), rewrite(value_type, env, options)}
              update_in(acc.optional, fn optionals -> [opt | optionals] end)

            {key, value_type}, acc when is_atom(key) or is_integer(key) or is_binary(key) ->
              # A basic fixed key for a static 'struct like' map
              fix = {key, rewrite(value_type, env, options)}
              update_in(acc.fixed, fn fixeds -> [fix | fixeds] end)

            {key_type, value_type}, acc ->
              # Otherwise, it is shorthand for `required(key) => value`
              req_key = rewrite(key_type, env, options)
              req_value = rewrite(value_type, env, options)
              # IO.inspect({req_key, req_value}, label: :asdf)

              case req_key do
                # `required(literal(key))`
                {{:., _, [{:__aliases__, _, [:TypeCheck, :Builtin]}, :literal]}, _, [fixed_key]} ->
                  update_in(acc.fixed, fn fixeds -> [{fixed_key, req_value} | fixeds] end)

                _ ->
                  update_in(acc.required, fn requireds -> [{req_key, req_value} | requireds] end)
              end

            other, _acc ->
              raise """
              Unknown syntax in map type literal: #{inspect(other)}.
              """
          end)

        quote generated: true, location: :keep do
          TypeCheck.Builtin.fancy_map(
            unquote(field_types.fixed),
            unquote(field_types.required),
            unquote(field_types.optional)
          )
        end

        # _other ->
        #   # Unhandled already-expanded structs
        #   # Treat them as literal values
        #   quote generated: true, location: :keep do
        #     TypeCheck.Builtin.literal(unquote(orig_ast))
        #   end
    end
  end

  defp rewrite_struct(struct_name, fields, env, options) do
    explicit_field_types =
      fields
      |> Enum.map(fn {key, value_type} -> {key, rewrite(value_type, env, options)} end)
      |> Enum.into(%{})

    expanded_struct_name = Macro.expand(struct_name, env)
    rewritten_struct_name = rewrite(struct_name, env, options)

    # The following is necessary because `%Foo{}` does not equal the type `%{__struct__: Foo}`
    # but  rather `%{__struct__: Foo, some_key: any(), some_other_key: any()}`
    # (using the keys from the `defstruct`)
    default_fields =
      try do
        Macro.struct!(expanded_struct_name, env)
      rescue
        err in [CompileError] ->
          pretty_type =
            quote do
              %unquote(struct_name){unquote_splicing(fields)}
            end

          description = """

          Could not look up default fields for struct type #{Macro.to_string(pretty_type)}.
          This usually means that the type is used in the same module
          as the `defstruct`, but before it.

          Try changing e.g.
          ```
          @type! t() :: %__MODULE__{}
          defstruct [:some, :fields]
          ```

          to:
          ```
          defstruct [:some, :fields]
          @type! t() :: %__MODULE__{}
          ```

          See https://github.com/Qqwy/elixir-type_check/issues/83
          for more information.
          """

          fields =
            err
            |> Map.from_struct()
            |> Map.to_list()
            |> Keyword.replace(:description, description)

          raise CompileError, fields
      end

    default_field_types =
      default_fields
      |> Map.from_struct()
      |> Map.keys()
      |> Enum.map(fn key ->
        {key,
         quote do
           TypeCheck.Builtin.any()
         end}
      end)
      |> Enum.into(%{})

    field_types = Map.merge(default_field_types, explicit_field_types) |> Enum.to_list()

    quote generated: true, location: :keep do
      TypeCheck.Builtin.fixed_map(
        [__struct__: unquote(rewritten_struct_name)] ++ unquote(field_types)
      )
    end
  end
end
