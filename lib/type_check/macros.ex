defmodule TypeCheck.Macros do
  @moduledoc """
  Contains the `spec`, `type`, `typep`, `opaque` macros to define runtime-checked function- and type-specifications.

  ## Usage

  This module is included by calling `use TypeCheck`.
  This will set up the module to use the special macros.


  ### Avoiding naming conflicts with TypeCheck.Builtin

  If you want to define a type with the same name as one in TypeCheck.Builtin,
  you should hide those particular functions from TypeCheck.Builtin by adding
  an `import TypeCheck.Builtin, except: [...]`-statement
  below the `use TypeCheck` manually.
  """
  defmacro __using__(_options) do
    quote location: :keep do
      import TypeCheck.Macros

      Module.register_attribute(__MODULE__, TypeCheck.TypeDefs, accumulate: true)
      Module.register_attribute(__MODULE__, TypeCheck.Specs, accumulate: true)
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

    # And now, define all specs:
    definitions = Module.definitions_in(env.module)
    specs = Module.get_attribute(env.module, TypeCheck.Specs)
    spec_quotes = wrap_functions_with_specs(specs, definitions, env)

    # And now for the tricky bit ;-)
    quote do
      import __MODULE__.TypeCheck

      unquote(spec_quotes)
    end
  end

  defp wrap_functions_with_specs(specs, definitions, caller) do
    for {name, line, arity, clean_params, params_ast, return_type_ast} <- specs do
      unless {name, arity} in definitions do
        raise ArgumentError, "spec for undefined function #{name}/#{arity}"
      end

      require TypeCheck.Type
      param_types = Enum.map(params_ast, &TypeCheck.Type.build_unescaped(&1, caller, true))
      return_type = TypeCheck.Type.build_unescaped(return_type_ast, caller, true)

      {params_spec_code, return_spec_code} = TypeCheck.Spec.prepare_spec_wrapper_code(name, param_types, clean_params, return_type, caller)

      TypeCheck.Spec.wrap_function_with_spec(name, line, arity, clean_params, params_spec_code, return_spec_code)
    end
  end

  @doc """
  Define a public type specification.

  This behaves similarly to Elixir's builtin `@type` attribute,
  and will create a type whose name and definition are public.

  Calling this macro will:

  - Fill the `@type`-attribute with a Typespec-friendly
    representation of the TypeCheck type.
  - Add a (or append to an already existing) `@typedoc` detailing that the type is
    managed by TypeCheck, and containing the full definition of the TypeCheck type.
  - Define a (hidden) public function with the same name (and arity) as the type
    that returns the TypeCheck.Type as a datastructure when called.
    This makes the type usable in calls to:
    - definitions of other type-specifications (in the same or different modules).
    - definitions of function-specifications (in the same or different modules).
    - `TypeCheck.conforms/2` and variants,
    - `TypeCheck.Type.build/1`
  """
  defmacro type(typedef) do
    define_type(typedef, :type, __CALLER__)
  end

  @doc """
  Define a private type specification.

  This behaves similarly to Elixir's builtin `@typep` attribute,
  and will create a type whose name and definition is private
  (therefore only usable in the current module).

  - Fill the `@typep`-attribute with a Typespec-friendly
    representation of the TypeCheck type.
  - Define a private function with the same name (and arity) as the type
    that returns the TypeCheck.Type as a datastructure when called.
    This makes the type usable in calls (in the same module) to:
      - definitions of other type-specifications
      - definitions of function-specifications
      - `TypeCheck.conforms/2` and variants,
      - `TypeCheck.Type.build/1`
  """
  defmacro typep(typedef) do
    define_type(typedef, :typep, __CALLER__)
  end

  @doc """
  Define a opaque type specification.


  This behaves similarly to Elixir's builtin `@opaque` attribute,
  and will create a type whose name is public
  but whose definition is private.


  Calling this macro will:

  - Fill the `@opaque`-attribute with a Typespec-friendly
    representation of the TypeCheck type.
  - Add a (or append to an already existing) `@typedoc` detailing that the type is
    managed by TypeCheck, and containing the name of the TypeCheck type.
    (not the definition, since it is an opaque type).
  - Define a (hidden) public function with the same name (and arity) as the type
    that returns the TypeCheck.Type as a datastructure when called.
    This makes the type usable in calls to:
    - definitions of other type-specifications (in the same or different modules).
    - definitions of function-specifications (in the same or different modules).
    - `TypeCheck.conforms/2` and variants,
    - `TypeCheck.Type.build/1`

  """
  defmacro opaque(typedef) do
    define_type(typedef, :opaque, __CALLER__)
  end

  @doc """
  Define a function specification.

  A function specification will wrap the function
  with checks that each of its parameters are of the types it expects.
  as well as checking that the return type is as expected.
  """
  defmacro spec(specdef) do
    define_spec(specdef, __CALLER__)
  end

  defp define_type({:when, _, [{:"::", _, [name_with_maybe_params, type]}, guard_ast]}, kind, caller) do
    define_type({:"::", [], [name_with_maybe_params, {:when, [], [type, guard_ast]}]}, kind, caller)
  end

  defp define_type({:"::", _meta, [name_with_maybe_params, type]}, kind, caller) do
    clean_typedef = TypeCheck.Internals.ToTypespec.full_rewrite(type, caller)
    new_typedoc =
      case kind do
        :typep -> false
        _ ->
          append_typedoc(caller, """
          This type is managed by `TypeCheck`,
          which allows checking values against the type at runtime.

          Full definition: #{type_definition_doc(name_with_maybe_params, type, kind)}
          """)
      end
    type = TypeCheck.Internals.PreExpander.rewrite(type, caller)

    res = type_fun_definition(name_with_maybe_params, type)
    quote location: :keep do
      case unquote(kind) do
        :opaque ->
          @typedoc unquote(new_typedoc)
          @opaque unquote(name_with_maybe_params) :: unquote(clean_typedef)
        :type ->
          @typedoc unquote(new_typedoc)
          @type unquote(name_with_maybe_params) :: unquote(clean_typedef)
        :typep ->
          @typep unquote(name_with_maybe_params) :: unquote(clean_typedef)
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

  defp type_definition_doc(name_with_maybe_params, type_ast, kind) do
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

  defp type_fun_definition(name_with_params, type) do
    {_name, params} = Macro.decompose_call(name_with_params)
    params_check_code =
      params
      |> Enum.map(fn param ->
      quote do
        TypeCheck.Type.ensure_type!(unquote(param))
      end
    end)
    quote location: :keep do
      @doc false
      def unquote(name_with_params) do
        unquote_splicing(params_check_code)
        # import TypeCheck.Builtin
        unquote(type)
      end
    end
  end

  defp define_spec({:"::", _meta, [name_with_params_ast, return_type_ast]}, caller) do
    {name, params_ast} = Macro.decompose_call(name_with_params_ast)
    arity = length(params_ast)

    # require TypeCheck.Type
    # param_types = Enum.map(params_ast, &TypeCheck.Type.build_unescaped(&1, caller))
    # return_type = TypeCheck.Type.build_unescaped(return_type_ast, caller)

    clean_params = Macro.generate_arguments(arity, caller.module)

    spec_fun_name = :"__type_check_spec_for_#{name}/#{arity}__"
    quote location: :keep do
      Module.put_attribute(__MODULE__, TypeCheck.Specs, {unquote(name), unquote(caller.line), unquote(arity), unquote(Macro.escape(clean_params)), unquote(Macro.escape(params_ast)), unquote(Macro.escape(return_type_ast))})

      def unquote(spec_fun_name)() do
        # import TypeCheck.Builtin
        %TypeCheck.Spec{name: unquote(name), param_types: unquote(params_ast), return_type: unquote(return_type_ast)}
      end
    end
  end
end
