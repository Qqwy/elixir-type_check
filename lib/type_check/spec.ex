defmodule TypeCheck.Spec do
  defstruct [:name, :param_types, :return_type]

  def spec_for(module, function, arity) do
    spec_fun_name = :"__type_check_spec_for_#{function}/#{arity}__"
    if function_exported?(module, spec_fun_name, 0) do
      {:ok, apply(module, spec_fun_name, [])}
    else
      {:error, :not_found}
    end
  end

  defimpl Inspect do
    def inspect(struct, opts) do
      body =
        Inspect.Algebra.container_doc("(", struct.param_types, ")", opts, &TypeCheck.Protocols.Inspect.inspect/2, [separator: ", ", break: :maybe])
      |> Inspect.Algebra.group

      "#TypeCheck.Spec<"
      |> Inspect.Algebra.glue(to_string(struct.name))
      |> Inspect.Algebra.concat(body)
      |> Inspect.Algebra.glue("::")
      |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(struct.return_type, opts))
      |> Inspect.Algebra.glue(">")
      |> Inspect.Algebra.group
    end
  end
end
