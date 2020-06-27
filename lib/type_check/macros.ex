defmodule TypeCheck.Macros do
  defmacro __using__(_options) do
    quote do
      import TypeCheck.Macros

      Module.register_attribute(__MODULE__, TypeCheck.TypeDefs, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, TypeCheck.Specs, accumulate: true, persist: true)
      @before_compile TypeCheck.Macros
    end
  end

  defmacro __before_compile__(env) do
    defs =
      Module.get_attribute(env.module, TypeCheck.TypeDefs)

    Module.create(Module.concat(env.module, TypeCheck), quote do
      @moduledoc false
      # This extra module is created
      # so that we can already access the custom user types
      # at compile-time
      # _inside_ the module they will be part of
      unquote(defs)
    end, env)

    # And now, override all specs:
    definitions = Module.definitions_in(env.module)
    IO.inspect(definitions, label: :definitions)
    specs = Module.get_attribute(env.module, TypeCheck.Specs)
    spec_quotes = for {name, line, arity, clean_params, params_spec_code, return_spec_code} <- specs do
      unless {name, arity} in definitions do
        raise ArgumentError, "spec for undefined function #{name}/#{arity}"
      end

      quote line: line do
        defoverridable([{unquote(name), unquote(arity)}])
        def unquote(name)(unquote_splicing(clean_params)) do
          import TypeCheck.Builtin

          unquote(params_spec_code)
          var!(super_result, nil) = super(unquote_splicing(clean_params))
          # TODO check result
          unquote(return_spec_code)
          var!(super_result, nil)
        end
      end
    end

    # Time to combine it all
    res = quote do
      import __MODULE__.TypeCheck

      unquote(spec_quotes)
    end

    IO.puts(Macro.to_string(res))
    res
  end

  defmacro type(typedef) do
    define_type(typedef, :type, __CALLER__)
  end

  defmacro typep(typedef) do
    define_type(typedef, :typep, __CALLER__)
  end

  defmacro opaque(typedef) do
    define_type(typedef, :opaque, __CALLER__)
  end

  defmacro spec(specdef) do
    define_spec(specdef, __CALLER__)
  end

  defp define_type(typedef = {:"::", _meta, [name_with_maybe_params, type]}, kind, caller) do
    {name, params} = Macro.decompose_call(name_with_maybe_params)

    new_typedoc =
      case kind do
        :typep -> false
        _ ->
          append_typedoc(caller, """
          This type is managed by `TypeCheck`,
          which allows checking values against the type at runtime.

          Full definition: #{type_definition_doc(name_with_maybe_params, type, kind, caller)}
          """)
      end
    type = TypeCheck.Internals.PreExpander.rewrite(type, caller)

    res = type_fun_definition(new_typedoc, typedef, name_with_maybe_params, type)
    IO.inspect(res)
    IO.puts(Macro.to_string(res))
    quote do
      case unquote(kind) do
        :opaque ->
          @typedoc unquote(new_typedoc)
          @opaque unquote(typedef)
        :type ->
          @typedoc unquote(new_typedoc)
          @type unquote(typedef)
        :typep ->
          @typep unquote(typedef)
      end
      unquote(res)
      Module.put_attribute(__MODULE__, TypeCheck.TypeDefs, unquote(Macro.escape(res)))
    end
  end

  defp append_typedoc(caller, extra_doc) do
    {_line, old_doc} = Module.get_attribute(caller.module, :typedoc) || {0, ""}
    newdoc = old_doc <> extra_doc
    Module.delete_attribute(caller.module, :typedoc)
    newdoc
  end

  defp type_definition_doc(name_with_maybe_params, type_ast, kind, caller) do
    head = Macro.to_string(name_with_maybe_params)
    if kind == :opaque do
       """
       `head` _(opaque type)_
       """
    else
      """
      `#{head} :: #{Macro.to_string(type_ast)}`
      """
    end
  end

  defp type_fun_definition(typedoc, typedef, name_with_params, macro_body) do
    quote do
      @doc false
      def unquote(name_with_params) do
        import TypeCheck.Builtin
        unquote(macro_body)
      end
    end
  end

  defp expand(type), do: type


  defp define_spec(specdef = {:"::", _meta, [name_with_params_ast, return_type_ast]}, caller) do
    {name, params_ast} = Macro.decompose_call(name_with_params_ast)
    arity = length(params_ast)
    # TODO currently assumes the params are directly types
    # rather than the possibility of named types like `x :: integer()`

    params_ast = Enum.map(params_ast, &TypeCheck.Internals.PreExpander.rewrite(&1, caller))
    return_type_ast = TypeCheck.Internals.PreExpander.rewrite(return_type_ast, caller)

    IO.inspect({name, params_ast}, label: :define_spec)
    clean_params =
      Macro.generate_arguments(arity, caller.module)
    {params_spec_code, return_spec_code} = prepare_spec_wrapper_code(specdef, name, params_ast, clean_params, return_type_ast, caller)

    # Module.put_attribute(caller.module, TypeCheck.TypeDefs, Macro.escape(res))
    spec_fun_name = :"__type_check_spec_for_#{name}/#{arity}__"
    res = quote do
      Module.put_attribute(__MODULE__, TypeCheck.Specs, {unquote(name), unquote(caller.line), unquote(arity), unquote(Macro.escape(clean_params)), unquote(Macro.escape(params_spec_code)), unquote(Macro.escape(return_spec_code))})

      def unquote(spec_fun_name)() do
        import TypeCheck.Builtin
        %TypeCheck.Spec{name: unquote(name), param_types: unquote(params_ast), return_type: unquote(return_type_ast)}
      end
    end
    IO.puts(Macro.to_string(res))
    res
  end

  defp prepare_spec_wrapper_code(specdef, name, params_ast, clean_params, return_type_ast, caller) do
    params_code = params_check_code(params_ast, clean_params, caller)
    return_code = return_check_code(return_type_ast, caller)

    {params_code, return_code}
  end

  defp return_check_code(return_type_ast, caller) do
    IO.puts(Macro.to_string(return_type_ast))

    {return_type, []} = Code.eval_quoted(quote do import TypeCheck.Builtin; unquote(return_type_ast) end, [], caller)
    return_code_check = TypeCheck.Protocols.ToCheck.to_check(return_type, Macro.var(:super_result, nil))
    return_code = quote do
      case unquote(return_code_check) do
        :ok ->
          nil
        error ->
          raise ArgumentError, inspect(error)
      end
    end
  end

  defp params_check_code(params_ast, clean_params, caller) do
    paired_params =
      params_ast
      |> Enum.zip(clean_params)
      |> Enum.with_index
      |> Enum.map(fn {{param_ast, clean_param}, index} ->
        param_check_code(param_ast, clean_param, index, caller)
      end)
    code =
      quote line: caller.line do
        with unquote_splicing(paired_params) do
          # Run actual code
        else
            # TODO transform into humanly-readable error
          error ->
            raise ArgumentError, inspect(error)
        end
      end
    IO.puts(Macro.to_string(code))
    code
  end

  defp param_check_code(param_ast, clean_param, index, caller) do
    {param_type, []} = Code.eval_quoted(quote do import TypeCheck.Builtin; unquote(param_ast) end, [], caller)

    impl = TypeCheck.Protocols.ToCheck.to_check(param_type, clean_param)
    quote do
      {:ok, _index, _param_type} <- {unquote(impl), unquote(index), unquote(Macro.escape(param_type))}
    end
  end
end
