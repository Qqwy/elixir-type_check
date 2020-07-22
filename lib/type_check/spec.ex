defmodule TypeCheck.Spec do
  defstruct [:name, :param_types, :return_type]

  defp spec_fun_name(function, arity) do
    :"__type_check_spec_for_#{function}/#{arity}__"
  end

  def lookup(module, function, arity) do
    Code.ensure_loaded(module)

    if function_exported?(module, spec_fun_name(function, arity), 0) do
      {:ok, apply(module, spec_fun_name(function, arity), [])}
    else
      {:error, :not_found}
    end
  end

  def lookup!(module, function, arity) do
    {:ok, res} = lookup(module, function, arity)
    res
  end

  def defined?(module, function, arity) do
    Code.ensure_loaded(module)
    function_exported?(module, spec_fun_name(function, arity), 0)
  end

  @doc false
  def create_spec_def(name, arity, param_types, return_type) do
    spec_fun_name = spec_fun_name(name, arity)

    res = quote location: :keep do
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
    IO.puts(Macro.to_string(res))
    res
  end

  @doc false
  def wrap_function_with_spec(name, line, arity, clean_params, params_spec_code, return_spec_code) do
    quote line: line do
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

  defp params_check_code(name, arity, param_types, clean_params, caller) do
    paired_params =
      param_types
      |> Enum.zip(clean_params)
      |> Enum.with_index()
      |> Enum.map(fn {{param_type, clean_param}, index} ->
        param_check_code(param_type, clean_param, index, caller)
      end)

    quote line: caller.line do
      with unquote_splicing(paired_params) do
        # Run actual code
      else
        {{:error, problem}, index, param_type} ->
          raise TypeCheck.TypeError,
                {unquote(spec_fun_name(name, arity))(), :param_error,
                 %{index: index, problem: problem}, unquote(clean_params)}
      end
    end
  end

  defp param_check_code(param_type, clean_param, index, _caller) do
    impl = TypeCheck.Protocols.ToCheck.to_check(param_type, clean_param)

    quote do
      {{:ok, _bindings}, _index, _param_type} <-
        {unquote(impl), unquote(index), unquote(Macro.escape(param_type))}
    end
  end

  defp return_check_code(name, arity, clean_params, return_type, _caller) do
    return_code_check =
      TypeCheck.Protocols.ToCheck.to_check(return_type, Macro.var(:super_result, nil))

    quote do
      case unquote(return_code_check) do
        {:ok, _bindings} ->
          nil

        {:error, problem} ->
          raise TypeCheck.TypeError,
                {unquote(spec_fun_name(name, arity))(), :return_error,
                 %{problem: problem, arguments: unquote(clean_params)}, var!(super_result, nil)}
      end
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
end
