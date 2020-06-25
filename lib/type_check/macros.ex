defmodule TypeCheck.Macros do
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
    # TODO
    quote unquote: false do
      import __MODULE__.TypeCheck
      foo = mylist5() |> Map.keys()
      def example_spec, do: unquote(foo)
    end
    |> IO.inspect()
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


  defp define_spec(specdef = {:"::", _meta, [name_with_params, return_type]}, caller) do
    {name, params} = Macro.decompose_call(name_with_params)
    # TODO currently assumes the params are directly types
    # rather than the possibility of named types like `x :: integer()`
    IO.inspect({name, params}, label: :define_spec)
    res = spec_fun_defunition(specdef, name, params, caller)
    quote do
      Module.put_attribute(__MODULE__, TypeCheck.TypeDefs, unquote(Macro.escape(res)))
    end
  end

  defp spec_fun_defunition(specdef, name, params, caller) do
    defname = :"__spec_for_#{name}__"
    clean_params =
      Macro.generate_arguments(length(params), caller.module)

    # first_param = hd clean_params
    code = params_to_with(params, clean_params, caller)

    # code = TypeCheck.Protocols.ToCheck.to_check(TypeCheck.Builtin.integer(), first_param)

    quote do
      def unquote(defname)(unquote_splicing(clean_params)) do
        unquote(code)
      end
    end
  end

  defp params_to_with(params, clean_params, caller) do
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
      quote do
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
