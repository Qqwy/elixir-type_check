defmodule TypeCheck.Spec do
  defstruct [:name, :param_types, :return_type]

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
      {:ok, spec} -> spec
      _ -> raise ArgumentError, "No spec found for `#{inspect(module)}.#{to_string(function)}/#{arity}`"
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
  def create_spec_def(name, arity, param_types, return_type) do
    spec_fun_name = spec_fun_name(name, arity)

    quote generated: true, location: :keep do
      @doc false
      def unquote(spec_fun_name)() do
        # import TypeCheck.Builtin
        %TypeCheck.Spec{
          name: unquote(name),
          param_types: unquote(Macro.escape(param_types)),
          return_type: unquote(Macro.escape(return_type))
        }
      end
    end
  end

  @doc false
  def wrap_function_with_spec(name, line, arity, clean_params, params_spec_code, return_spec_code, typespec) do

    quote generated: true, location: :keep, line: line do
      if Module.get_attribute(__MODULE__, :autogen_typespec) do
        @spec unquote(typespec)
      end
      defoverridable([{unquote(name), unquote(arity)}])

      def unquote(name)(unquote_splicing(clean_params)) do
        # import TypeCheck.Builtin

        unquote(params_spec_code)
        var!(super_result, nil) = super(unquote_splicing(clean_params))
        unquote(return_spec_code)
        var!(super_result, nil)
      end

    end
  end

  @doc false
  def prepare_spec_wrapper_code(name, param_types, clean_params, return_type, caller) do
    arity = length(clean_params)
    params_code = params_check_code(name, arity, param_types, clean_params, caller)
    return_code = return_check_code(name, arity, clean_params, return_type, caller)

    {params_code, return_code}
  end

  defp params_check_code(_name, _arity = 0, _param_types, _clean_params, _caller) do
    # No check needed for arity-0 functions.
    # Also gets rid of a compiler warning 'else will never match'
    quote generated: true, location: :keep do end
  end
  defp params_check_code(name, arity, param_types, clean_params, caller) do
    paired_params =
      param_types
      |> Enum.zip(clean_params)
      |> Enum.with_index()
      |> Enum.map(fn {{param_type, clean_param}, index} ->
        param_check_code(param_type, clean_param, index, caller)
      end)

    quote line: caller.line, generated: true, location: :keep do
      with unquote_splicing(paired_params) do
        # Run actual code
      else
        {{:error, problem}, index, param_type} ->
          raise TypeCheck.TypeError,
          {
            {__MODULE__.unquote(spec_fun_name(name, arity))(), :param_error,
             %{index: index, problem: problem}, unquote(clean_params)}, unquote(Macro.Env.location(caller))}
      end
    end
  end

  defp param_check_code(param_type, clean_param, index, _caller) do
    impl = TypeCheck.Protocols.ToCheck.to_check(param_type, clean_param)

    quote generated: true, location: :keep do
      {{:ok, _bindings}, _index, _param_type} <-
        {unquote(impl), unquote(index), unquote(Macro.escape(param_type))}
    end
  end

  defp return_check_code(name, arity, clean_params, return_type, _caller) do
    return_code_check =
      TypeCheck.Protocols.ToCheck.to_check(return_type, Macro.var(:super_result, nil))

    quote generated: true, location: :keep do
      case unquote(return_code_check) do
        {:ok, _bindings} ->
          nil

        {:error, problem} ->
          raise TypeCheck.TypeError,
                {__MODULE__.unquote(spec_fun_name(name, arity))(), :return_error,
                 %{problem: problem, arguments: unquote(clean_params)}, var!(super_result, nil)}
      end
    end
  end

  @doc false
  def to_typespec(name, params_ast, return_type_ast, caller) do
    clean_param_types = Enum.map(params_ast, &TypeCheck.Internals.ToTypespec.full_rewrite(&1, caller))
    clean_return_type = TypeCheck.Internals.ToTypespec.full_rewrite(return_type_ast, caller)
    quote generated: true, location: :keep do
      unquote(name)(unquote_splicing(clean_param_types)) :: unquote(clean_return_type)
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(struct, opts) do
      body =
        Inspect.Algebra.container_doc(
          "(",
          struct.param_types,
          ")",
          opts,
          &TypeCheck.Protocols.Inspect.inspect/2,
          separator: ", ",
          break: :maybe
        )
        |> Inspect.Algebra.group()

      to_string(struct.name)
      |> Inspect.Algebra.concat(body)
      |> Inspect.Algebra.glue("::")
      |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(struct.return_type, opts))
      |> Inspect.Algebra.group()
    end
  end

  defimpl Elixir.Inspect do
    def inspect(struct, opts) do
      "#TypeCheck.Spec< "
      |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(struct, opts))
      |> Inspect.Algebra.glue(">")
      |> Inspect.Algebra.group()
    end
  end


  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        s.param_types
        |> Enum.map(&TypeCheck.Protocols.ToStreamData.to_gen/1)
        |> List.to_tuple
        |> StreamData.tuple
      end
    end
  end
end
