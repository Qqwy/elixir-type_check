defmodule TypeCheck.Spec do
  defmacro __before_compile__(env) do
    IO.inspect(env)
    IO.inspect(Module.get_attribute(env.module, TypeCheck.Spec.Raw))
    quote do
    end
  end


  defmacro type(args) do
    IO.inspect(args)
    {name, raw_type} = extract_type_name(args)
    quote do
      Module.put_attribute(__MODULE__, TypeCheck.Spec.Raw, {unquote(name), unquote(Macro.escape(raw_type))})
    end
  end

  defmacro typep(args) do
    IO.inspect(args)
    {name, raw_type} = extract_type_name(args)
    quote do
      Module.put_attribute(__MODULE__, TypeCheck.Spec.Raw, {unquote(name), unquote(Macro.escape(raw_type))})
    end
  end

  defmacro opaque(args) do
    IO.inspect(args)
    quote do
      44
    end
  end

  defmacro spec(args) do
    IO.inspect(args)
    quote do
      45
    end
  end

  defp extract_type_name(ast = {:"::", _, [name, type]}) do
    case extract_var_name(name) do
      {:ok, var} ->
        {var, type}
      :error ->
        raise "Expected type name to be a variable, but got `#{Macro.to_string(name)}` while parsing #{Macro.to_string(ast)}"
    end
  end

  defp extract_type_name(other) do
    raise "Expected a definition in the shape of `name :: type` but got `#{Macro.to_string(other)}`"
  end

  defp extract_var_name({name, _, module}) when is_atom(name) and is_atom(module), do: {:ok, name}
  defp extract_var_name(_), do: :error
end
