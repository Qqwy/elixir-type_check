defmodule TypeCheck.Macros do
  defmacro __using__(_options) do
    quote do
      import TypeCheck.Macros
      import TypeCheck.Builtin

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
          This type is managed by TypeCheck.
          Original definition: #{Macro.to_string(typedef)}
          """)
      end

    macro_body =
      type
      |> expand()

    res = type_fun_definition(new_typedoc, typedef, name_with_maybe_params, macro_body)
    IO.inspect(res)
    IO.puts(Macro.to_string(res))
    quote do
      @typedoc unquote(new_typedoc)
      @type unquote(typedef)
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

  defp type_fun_definition(typedoc, typedef, name_with_params, macro_body) do
    quote do
      @doc false
      def unquote(name_with_params) do
        unquote(macro_body)
      end
    end
  end

  # TODO
  # replace AST that are Kernel.SpecialForms
  # with alternatives
  # that refer to functions in TypeCheck.Builtin
  defp expand(type), do: type


  defp define_spec(specdef = {:"::", _meta, [name_with_params_ast, return_type_ast]}, caller) do
    {name, params_ast} = Macro.decompose_call(name_with_params_ast)
    arity = length(params_ast)
    # TODO currently assumes the params are directly types
    # rather than the possibility of named types like `x :: integer()`
    IO.inspect({name, params_ast}, label: :define_spec)
    clean_params =
      Macro.generate_arguments(arity, caller.module)
    {params_spec_code, return_spec_code} = prepare_spec_wrapper_code(specdef, name, params_ast, clean_params, return_type_ast, caller)

    # Module.put_attribute(caller.module, TypeCheck.TypeDefs, Macro.escape(res))
    spec_fun_name = :"__type_check_spec_for_#{name}/#{arity}__"
    res = quote do
      Module.put_attribute(__MODULE__, TypeCheck.Specs, {unquote(name), unquote(caller.line), unquote(arity), unquote(Macro.escape(clean_params)), unquote(Macro.escape(params_spec_code)), unquote(Macro.escape(return_spec_code))})

      def unquote(spec_fun_name)() do
        %TypeCheck.Spec{name: unquote(name), param_types: unquote(params_ast), return_type: unquote(return_type_ast)}
      end
    end
    IO.puts(Macro.to_string(res))
    res
  end

  defp prepare_spec_wrapper_code(specdef, name, params_ast, clean_params, return_type_ast, caller) do

    # first_param = hd clean_params
    params_code = params_check_code(params_ast, clean_params, caller)
    return_code = return_check_code(return_type_ast, caller)


    {params_code, return_code}

    # code = TypeCheck.Protocols.ToCheck.to_check(TypeCheck.Builtin.integer(), first_param)

    # quote do
    #   def unquote(defname)(unquote_splicing(clean_params)) do
    #     unquote(code)
    #   end
    # end
  end

  defp return_check_code(return_type_ast, caller) do
    {return_type, []} = Code.eval_quoted(return_type_ast, [], caller)
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

  defp params_check_code(params, clean_params, caller) do
    paired_params =
      params
      |> Enum.zip(clean_params)
      |> Enum.with_index
      |> Enum.map(fn {{param, clean_param}, index} ->
        {param_type, []} = Code.eval_quoted(param, [], caller)
        impl = TypeCheck.Protocols.ToCheck.to_check(param_type, clean_param)
        quote do
          {:ok, _index, _param_type} <- {unquote(impl), unquote(index), unquote(Macro.escape(param_type))}
        end
      end)
    code =
      quote line: caller.line do
        with unquote_splicing(paired_params) do
          # Run actual code
        else
            # TODO transform into humanly-readable code
            # and raise it as exception
          error ->
            raise ArgumentError, inspect(error)
        end
      end
    IO.puts(Macro.to_string(code))
    code
  end
end
