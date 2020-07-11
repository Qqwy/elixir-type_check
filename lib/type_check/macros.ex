defmodule TypeCheck.Macros do
  @moduledoc """
  Contains the `spec`, `type`, `typep`, `opaque` macros to define runtime-checked function- and type-specifications.

  ## Usage

  This module is included by calling `use TypeCheck`.
  This will set up the module to use the special macros.


  ### Avoiding naming conflicts with TypeCheck.Builtin

  If you want to define a type with the same name as one in TypeCheck.Builtin,
  _(which is not particularly recommended)_,
  you should hide those particular functions from TypeCheck.Builtin by adding
  `import TypeCheck.Builtin, except: [...]`
  below `use TypeCheck` manually.
  """
  defmacro __using__(_options) do
    quote location: :keep do
      import TypeCheck.Macros, only: [type: 1, typep: 1, opaque: 1, spec: 1]
      @compile {:inline_size, 1080}

      Module.register_attribute(__MODULE__, TypeCheck.TypeDefs, accumulate: true)
      Module.register_attribute(__MODULE__, TypeCheck.Specs, accumulate: true)
      @before_compile TypeCheck.Macros
    end
  end

  defmacro __before_compile__(env) do
    defs = Module.get_attribute(env.module, TypeCheck.TypeDefs)

    compile_time_imports_module_name = Module.concat(TypeCheck.Internals.UserTypes, env.module)

    Module.create(
      compile_time_imports_module_name,
      quote do
        @moduledoc false
        # This extra module is created
        # so that we can already access the custom user types
        # at compile-time
        # _inside_ the module they will be part of
        unquote(defs)
      end,
      env
    )

    # And now, define all specs:
    definitions = Module.definitions_in(env.module)
    specs = Module.get_attribute(env.module, TypeCheck.Specs)
    spec_defs = create_spec_defs(specs, definitions, env)
    spec_quotes = wrap_functions_with_specs(specs, definitions, env)

    # And now for the tricky bit ;-)
    quote do
      unquote(spec_defs)

      import unquote(compile_time_imports_module_name)

      unquote(spec_quotes)
    end
  end

  defp create_spec_defs(specs, definitions, caller) do
    for {name, line, arity, _clean_params, params_ast, return_type_ast} <- specs do
      TypeCheck.Spec.create_spec_def(name, arity, params_ast, return_type_ast)
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

      {params_spec_code, return_spec_code} =
        TypeCheck.Spec.prepare_spec_wrapper_code(
          name,
          param_types,
          clean_params,
          return_type,
          caller
        )

      TypeCheck.Spec.wrap_function_with_spec(
        name,
        line,
        arity,
        clean_params,
        params_spec_code,
        return_spec_code
      )
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

  ## Usage

  The syntax is essentially the same as for the built-in `@type` attribute:

  ```elixir
  type type_name :: type_description
  ```

  It is possible to create parameterized types as well:

  ```
  type dict(key, value) :: [{key, value}]
  ```

  ### Named types

  You can also introduce named types:

  ```
  type color :: {red :: integer, green :: integer, blue :: integer}
  ```
  Not only is this nice to document that the same type
  is being used for different purposes,
  it can also be used with a 'type guard' to add custom checks
  to your type specifications:

  ```
  type sorted_pair(a, b) :: {first :: a, second :: b} when first <= second
  ```

  """
  defmacro type(typedef) do
    define_type(typedef, :type, __CALLER__)
  end

  @doc """
  Define a private type specification.

  This behaves similarly to Elixir's builtin `@typep` attribute,
  and will create a type whose name and structure is private
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

  `typep/1` accepts the same typedef expression as `type/1`.
  """
  defmacro typep(typedef) do
    define_type(typedef, :typep, __CALLER__)
  end

  @doc """
  Define a opaque type specification.


  This behaves similarly to Elixir's builtin `@opaque` attribute,
  and will create a type whose name is public
  but whose structure is private.


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

  `opaque/1` accepts the same typedef expression as `type/1`.
  """
  defmacro opaque(typedef) do
    define_type(typedef, :opaque, __CALLER__)
  end

  @doc """
  Define a function specification.

  A function specification will wrap the function
  with checks that each of its parameters are of the types it expects.
  as well as checking that the return type is as expected.

  ## Usage

  The syntax is essentially the same as for built-in `@spec` attributes:

  ```
  spec function_name(type1, type2) :: return_type
  ```

  It is also allowed to introduce named types:

  ```
  spec days_since_epoch(year :: integer, month :: integer, day :: integer) :: integer
  ```

  Note that `TypeCheck` does _not_ allow the `when` keyword to be used
  to restrict the types of recurring type variables (which Elixir's
  builtin Typespecs allow). This is because:

  - Usually it is more clear to give a recurring type
    an explicit name.
  - The `when` keyword is used instead for TypeCheck's type guards'.
    (See `TypeCheck.Builtin.guarded_by/2` for more information.)

  """
  defmacro spec(specdef) do
    define_spec(specdef, __CALLER__)
  end

  defp define_type(
         {:when, _, [{:"::", _, [name_with_maybe_params, type]}, guard_ast]},
         kind,
         caller
       ) do
    define_type(
      {:"::", [], [name_with_maybe_params, {:when, [], [type, guard_ast]}]},
      kind,
      caller
    )
  end

  defp define_type({:"::", _meta, [name_with_maybe_params, type]}, kind, caller) do
    clean_typedef = TypeCheck.Internals.ToTypespec.full_rewrite(type, caller)

    new_typedoc =
      case kind do
        :typep ->
          false

        _ ->
          append_typedoc(caller, """
          This type is managed by `TypeCheck`,
          which allows checking values against the type at runtime.

          Full definition:

          #{type_definition_doc(name_with_maybe_params, type, kind, caller)}
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

  defp type_definition_doc(name_with_maybe_params, type_ast, kind, caller) do
    head = Macro.to_string(name_with_maybe_params)

    if kind == :opaque do
      """
      `head` _(opaque type)_
      """
    else
      type_ast =
        Macro.prewalk(type_ast, fn
          lazy_ast = {:lazy, _, _} -> lazy_ast
          ast -> Macro.expand(ast, caller)
        end)

      """
      ```
      #{head} :: #{Macro.to_string(type_ast)}
      ```
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
        unquote(type_expansion_loop_prevention_code(name_with_params))
        unquote(type)
      end
    end
  end

  # If a type is refered to more than 1_000_000 times
  # we're probably in a type expansion loop
  defp type_expansion_loop_prevention_code(name_with_params) do
    key = {Macro.escape(name_with_params), :expansion_tracker}

    quote do
      expansion_tracker = Process.get({__MODULE__, unquote(key)}, 0)

      if expansion_tracker > 1_000_000 do
        IO.warn("""
        Potentially infinite type expansion loop detected while expanding `#{
          unquote(Macro.to_string(name_with_params))
        }`.
        You probably want to use `TypeCheck.Builtin.lazy` to defer type expansion to runtime.
        """)
      else
        Process.put({__MODULE__, unquote(key)}, expansion_tracker + 1)
      end
    end
  end

  defp define_spec({:"::", _meta, [name_with_params_ast, return_type_ast]}, caller) do
    {name, params_ast} = Macro.decompose_call(name_with_params_ast)
    arity = length(params_ast)
    # return_type_ast = TypeCheck.Internals.PreExpander.rewrite(return_type_ast, caller)

    # require TypeCheck.Type
    # param_types = Enum.map(params_ast, &TypeCheck.Type.build_unescaped(&1, caller))
    # return_type = TypeCheck.Type.build_unescaped(return_type_ast, caller)

    clean_params = Macro.generate_arguments(arity, caller.module)

    spec_fun_name = :"__type_check_spec_for_#{name}/#{arity}__"

    quote location: :keep do
      Module.put_attribute(
        __MODULE__,
        TypeCheck.Specs,
        {unquote(name), unquote(caller.line), unquote(arity), unquote(Macro.escape(clean_params)),
         unquote(Macro.escape(params_ast)), unquote(Macro.escape(return_type_ast))}
      )

      # def unquote(spec_fun_name)() do
      #   # import TypeCheck.Builtin
      #   %TypeCheck.Spec{
      #     name: unquote(name),
      #     param_types: unquote(params_ast),
      #     return_type: unquote(return_type_ast)
      #   }
      # end
    end
  end

  import Kernel, except: [@: 1]
  defmacro @ast do
    IO.inspect(ast)
    case ast do
      {name, _, expr} when name in ~w[type typep opaque spec]a ->
        # apply(TypeCheck.Macros, name, expr)
        quote do
          TypeCheck.Macros.unquote(name)(unquote_splicing(expr))
        end
      _ ->
        quote do
          Kernel.@(unquote(ast))
        end
      end
  end
end
