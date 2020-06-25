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
      # |> wrap_params_with_unquote(params)
      # |> manually_wrap_in_quote()

    res = macro_definition(new_typedoc, typedef, name_with_maybe_params, macro_body)
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

  defp macro_definition(typedoc, typedef, name_with_params, macro_body) do
    quote do
      @doc false
      def unquote(name_with_params) do
        unquote(macro_body)
      end
    end
  end

  # Given a list of parameters
  # that each are Elixir ASTs like `{:a, _, Elixir}`
  # will wrap all instances where that same AST is used in `type_ast`
  # with calls to `unquote`.
  defp wrap_params_with_unquote(type_ast, params) do
    Macro.postwalk(type_ast, &wrap_param_with_unquote(&1, params))
  end

  defp wrap_param_with_unquote(type_ast_node, params) do
    if type_ast_node in params do
      # Note that we need to construct the `unquote` AST-node
      # manually because we need to delay wrapping it in `quote`
      # until later.
      {:unquote, [], [type_ast_node]}
      else
        type_ast_node
    end
  end

  # Required because writing the 'automatic' `quote do unquote(x) end`
  # would result in `x`, rather than in a quote with x's contents.
  defp manually_wrap_in_quote(x) do
    {:quote, [], [[do: x]]}
  end
end
