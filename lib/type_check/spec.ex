defmodule TypeCheck.Spec do
  defstruct [
    :name,
    :param_types,
    :return_type,
    :location
  ]

  import TypeCheck.Internals.Bootstrap.Macros

  if_recompiling? do
    use TypeCheck
    alias TypeCheck.DefaultOverrides.String

    @type! t() :: %__MODULE__{
             name: String.t(),
             param_types: list(TypeCheck.Type.t()),
             return_type: TypeCheck.Type.t(),
             location: [] | list({:file, String.t()} | {:line, non_neg_integer()})
           }
    @type! problem_tuple ::
             {t(), :param_error,
              %{
                index: non_neg_integer(),
                problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple())
              }, list(any())}
             | {t(), :return_error,
                %{
                  arguments: list(term()),
                  problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple())
                }, list(any())}
  end

  defp spec_fun_name(function, arity) do
    :"__TypeCheck spec for '#{function}/#{arity}'__"
  end

  @doc """
  Looks up the spec for a particular `{module, function, arity}`.

  On success, returns `{:ok, spec}`.
  On failure, returns `{:error, :not_found}`.

  This is quite an advanced low-level function,
  which you usually won't need to interact with directly.


  c.f. `lookup!/3`.

      iex(1)> defmodule Example do
      ...(2)>   use TypeCheck
      ...(3)>   @spec! greeter(name :: binary()) :: binary()
      ...(4)>   def greeter(name), do: "Hello, \#{name}!"
      ...(5)> end
      ...(6)>
      ...(7)> {:ok, spec} = TypeCheck.Spec.lookup(Example, :greeter, 1)
      ...(8)> spec
      #TypeCheck.Spec<  greeter(name :: binary()) :: binary() >

      iex> TypeCheck.Spec.lookup(Example, :nonexistent, 0)
      {:error, :not_found}
  """
  def lookup(module, function, arity) do
    Code.ensure_loaded(module)

    if function_exported?(module, spec_fun_name(function, arity), 0) do
      {:ok, apply(module, spec_fun_name(function, arity), [])}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Looks up the spec for a particular `{module, function, arity}`.

  On success, returns `spec`.
  Raises when the spec cannot be found.

  c.f. `lookup/3`.

      iex(1)> defmodule Example2 do
      ...(2)>   use TypeCheck
      ...(3)>   @spec! greeter(name :: binary()) :: binary()
      ...(4)>   def greeter(name), do: "Hello, \#{name}!"
      ...(5)> end
      ...(6)>
      ...(7)> TypeCheck.Spec.lookup!(Example2, :greeter, 1)
      #TypeCheck.Spec<  greeter(name :: binary()) :: binary() >

      iex> TypeCheck.Spec.lookup!(Example2, :nonexistent, 0)
      ** (ArgumentError) No spec found for `Example2.nonexistent/0`
  """
  def lookup!(module, function, arity) do
    case lookup(module, function, arity) do
      {:ok, spec} ->
        spec

      _ ->
        raise ArgumentError,
              "No spec found for `#{inspect(module)}.#{to_string(function)}/#{arity}`"
    end
  end

  @doc """
  True if a spec was added to `{module, function, arity}`.

  c.f. `lookup/3`.

      iex(1)> defmodule Example3 do
      ...(2)>   use TypeCheck
      ...(3)>   @spec! greeter(name :: binary()) :: binary()
      ...(4)>   def greeter(name), do: "Hello, \#{name}!"
      ...(5)> end
      ...(6)>
      ...(7)> TypeCheck.Spec.defined?(Example3, :greeter, 1)
      true
      ...(8)> TypeCheck.Spec.defined?(Example3, :nonexistent, 0)
      false
  """
  def defined?(module, function, arity) do
    Code.ensure_loaded(module)
    function_exported?(module, spec_fun_name(function, arity), 0)
  end

  @doc false
  def create_spec_def(name, arity, param_types, return_type, {file, line}) do
    spec_fun_name = spec_fun_name(name, arity)
    escaped_param_types = Enum.map(param_types, &TypeCheck.Internals.Escaper.escape/1)

    quote generated: true, location: :keep do
      @doc false
      def unquote(spec_fun_name)() do
        # import TypeCheck.Builtin
        %TypeCheck.Spec{
          name: unquote(name),
          param_types: unquote(escaped_param_types),
          return_type: unquote(TypeCheck.Internals.Escaper.escape(return_type)),
          location: {unquote(file), unquote(line)}
        }
      end
    end
  end

  @doc false
  def check_function_kind(module, function, arity) do
    cond do
      Module.defines?(module, {function, arity}, :def) ->
        :def

      Module.defines?(module, {function, arity}, :defp) ->
        :defp

      Module.defines?(module, {function, arity}, :defmacro) ->
        :defmacro

      Module.defines?(module, {function, arity}, :defmacrop) ->
        :defmacrop

      true ->
        raise TypeCheck.CompileError,
              "cannot add spec to #{to_string(module)}.#{inspect(function)}/#{inspect(arity)} because it was not defined"
    end
  end

  @doc false
  def wrap_function_with_spec(
        name,
        _location,
        arity,
        clean_params,
        params_spec_code,
        return_spec_code,
        typespec,
        caller
      ) do
    return_spec_fun_name = :"__#{name}__type_check_return_spec__"

    body =
      quote do
        unquote(params_spec_code)
        super_result = super(unquote_splicing(clean_params))
        unquote(return_spec_fun_name)(super_result, unquote_splicing(clean_params))
      end

    # Check if original function is public or private
    function_kind = TypeCheck.Spec.check_function_kind(caller.module, name, arity)

    quote generated: true, location: :keep do
      if Module.get_attribute(__MODULE__, :autogen_typespec) do
        @spec unquote(typespec)
      end

      defoverridable([{unquote(name), unquote(arity)}])

      Kernel.unquote(function_kind)(unquote(name)(unquote_splicing(clean_params)),
        do: unquote(body)
      )

      # The result is checked in a separate function
      # This ensures we can convince Dialyzer to skip it. c.f. #85
      @compile {:inline, [{unquote(return_spec_fun_name), unquote(arity + 1)}]}
      @dialyzer {:nowarn_function, [{unquote(return_spec_fun_name), unquote(arity + 1)}]}

      Kernel.defp unquote(return_spec_fun_name)(
                    var!(super_result, nil),
                    unquote_splicing(clean_params)
                  ) do
        unquote(return_spec_code)
      end
    end
  end

  @doc false
  def prepare_spec_wrapper_code(name, param_types, clean_params, return_type, caller, location) do
    arity = length(clean_params)
    params_code = params_check_code(name, arity, param_types, clean_params, caller, location)
    return_code = return_check_code(name, arity, clean_params, return_type, caller, location)

    {params_code, return_code}
  end

  defp params_check_code(_name, _arity = 0, _param_types, _clean_params, _caller, _location) do
    # No check needed for arity-0 functions.
    # Also gets rid of a compiler warning 'else will never match'
    quote generated: true, location: :keep do
    end
  end

  defp params_check_code(name, arity, param_types, clean_params, caller, location) do
    paired_params =
      param_types
      |> Enum.zip(clean_params)
      |> Enum.with_index()
      |> Enum.flat_map(fn {{param_type, clean_param}, index} ->
        param_check_code(param_type, clean_param, index, caller, location)
      end)

    quote generated: true, location: :keep do
      with unquote_splicing(paired_params) do
        # Run actual code
      else
        {{:error, problem}, index} ->
          raise TypeCheck.TypeError,
                {
                  {__MODULE__.unquote(spec_fun_name(name, arity))(), :param_error,
                   %{index: index, problem: problem}, unquote(clean_params)},
                  unquote(Macro.Env.location(caller))
                }
      end
    end
  end

  defp param_check_code(param_type, clean_param, index, _caller, _location) do
    impl = TypeCheck.Protocols.ToCheck.to_check(param_type, clean_param)

    # {file, line} = location
    quote generated: true, location: :keep do
      [
        {{:ok, _bindings, altered_param}, _index} <- {unquote(impl), unquote(index)},
        clean_param = altered_param
      ]
    end
  end

  defp return_check_code(name, arity, clean_params, return_type, _caller, _location) do
    return_code_check =
      TypeCheck.Protocols.ToCheck.to_check(return_type, Macro.var(:super_result, nil))

    # {file, line} = location
    quote generated: true, location: :keep do
      case unquote(return_code_check) do
        {:ok, _bindings, altered_return_value} ->
          # IO.inspect(unquote(return_code_check), label: :return_check_code1, limit: :infinity)
          # IO.inspect(altered_return_value, label: :return_check_code2)
          altered_return_value

        {:error, problem} ->
          raise TypeCheck.TypeError,
                {__MODULE__.unquote(spec_fun_name(name, arity))(), :return_error,
                 %{problem: problem, arguments: unquote(clean_params)}, var!(super_result, nil)}
      end
    end
  end

  @doc false
  def to_typespec(name, params_ast, return_type_ast, caller) do
    clean_param_types =
      Enum.map(params_ast, &TypeCheck.Internals.ToTypespec.full_rewrite(&1, caller))

    clean_return_type = TypeCheck.Internals.ToTypespec.full_rewrite(return_type_ast, caller)

    quote generated: true, location: :keep do
      unquote(name)(unquote_splicing(clean_param_types)) :: unquote(clean_return_type)
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(struct, opts) do
      body =
        Inspect.Algebra.container_doc(
          Inspect.Algebra.color("(", :named_type, opts),
          struct.param_types,
          Inspect.Algebra.color(")", :named_type, opts),
          opts,
          &TypeCheck.Protocols.Inspect.inspect/2,
          separator: ", ",
          break: :maybe
        )
        |> Inspect.Algebra.group()
        |> Inspect.Algebra.color(:named_type, opts)

      to_string(struct.name)
      |> Inspect.Algebra.color(:named_type, opts)
      |> Inspect.Algebra.concat(body)
      |> Inspect.Algebra.glue(Inspect.Algebra.color("::", :named_type, opts))
      |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(struct.return_type, opts))
      |> Inspect.Algebra.color(:named_type, opts)
      |> Inspect.Algebra.group()
      |> Inspect.Algebra.color(:named_type, opts)
    end
  end

  defimpl Elixir.Inspect do
    def inspect(struct, opts) do
      "#TypeCheck.Spec< "
      |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(struct, opts))
      |> Inspect.Algebra.glue(">")
      |> Inspect.Algebra.group()
      |> Inspect.Algebra.color(:named_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        s.param_types
        |> Enum.map(&TypeCheck.Protocols.ToStreamData.to_gen/1)
        |> StreamData.fixed_list()

        # |> List.to_tuple
        # |> StreamData.tuple
      end
    end
  end
end
