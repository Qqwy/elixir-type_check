defmodule TypeCheck.Spec do
  defstruct [:name, :param_types, :return_type]

  def lookup(module, function, arity) do
    spec_fun_name = :"__type_check_spec_for_#{function}/#{arity}__"
    if function_exported?(module, spec_fun_name, 0) do
      {:ok, apply(module, spec_fun_name, [])}
    else
      {:error, :not_found}
    end
  end

  def lookup!(module, function, arity) do
    {:ok, res} = lookup(module, function, arity)
    res
  end

  def defined?(module, function, arity) do
    spec_fun_name = :"__type_check_spec_for_#{function}/#{arity}__"
    function_exported?(module, spec_fun_name, 0)
  end

  defimpl Inspect do
    def inspect(struct, opts) do
      body =
        Inspect.Algebra.container_doc("(", struct.param_types, ")", opts, &TypeCheck.Protocols.Inspect.inspect/2, [separator: ", ", break: :maybe])
      |> Inspect.Algebra.group

      "#TypeCheck.Spec< "
      |> Inspect.Algebra.glue(to_string(struct.name))
      |> Inspect.Algebra.concat(body)
      |> Inspect.Algebra.glue(" :: ")
      |> Inspect.Algebra.concat(TypeCheck.Protocols.Inspect.inspect(struct.return_type, opts))
      |> Inspect.Algebra.glue(" >")
      |> Inspect.Algebra.group
    end
  end

  @doc false
  def wrap_function_with_spec(name, line, arity, clean_params, params_spec_code, return_spec_code) do
    quote line: line do
      defoverridable([{unquote(name), unquote(arity)}])
      def unquote(name)(unquote_splicing(clean_params)) do
        import TypeCheck.Builtin

        unquote(params_spec_code)
        var!(super_result, nil) = super(unquote_splicing(clean_params))
        unquote(return_spec_code)
        var!(super_result, nil)
      end
    end
  end

  @doc false
  def prepare_spec_wrapper_code(specdef, name, param_types, clean_params, return_type, caller) do
    params_code = params_check_code(param_types, clean_params, caller)
    return_code = return_check_code(return_type, caller)

    {params_code, return_code}
  end

  defp params_check_code(param_types, clean_params, caller) do
    paired_params =
      param_types
      |> Enum.zip(clean_params)
      |> Enum.with_index
      |> Enum.map(fn {{param_type, clean_param}, index} ->
      param_check_code(param_type, clean_param, index, caller)
    end)
        quote line: caller.line do
        with unquote_splicing(paired_params) do
          # Run actual code
        else
          {{:error, error}, _index, _param_type} ->
            raise TypeCheck.TypeError, error
        end
      end
  end

  defp param_check_code(param_type, clean_param, index, caller) do

    impl = TypeCheck.Protocols.ToCheck.to_check(param_type, clean_param)
    quote do
      {{:ok, _bindings}, _index, _param_type} <- {unquote(impl), unquote(index), unquote(Macro.escape(param_type))}
    end
  end

  defp return_check_code(return_type, caller) do
    return_code_check = TypeCheck.Protocols.ToCheck.to_check(return_type, Macro.var(:super_result, nil))
    return_code = quote do
      case unquote(return_code_check) do
        {:ok, _bindings} ->
          nil
        {:error, error} ->
          raise TypeCheck.TypeError, error
      end
    end
  end
end
