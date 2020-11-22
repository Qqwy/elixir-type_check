defmodule TypeCheck.Internals.Overrides do
  @moduledoc false
  # Functionality to replace remote types
  # to which TypeCheck does not have access
  # with 'replacement' type-functions.

  # If `ast` is an override, it is rewritten to a call to this override.
  # If not, `ast` is returned unaltered.
  def rewrite_if_override(ast, overrides, env) do
    case Macro.decompose_call(ast) do
      :error -> # Not a call: not an override
        ast
      {_local_fun, _args} -> # Not a remote function: not an override
        ast
      {module, name, args} ->
        clean_module = Macro.expand(module, env)
        case search_override({clean_module, name, length(args)}, overrides) do
          :error ->
            ast
          {:ok, {replacement_module, replacement_name, _}} ->
            quote do
              unquote(replacement_module).unquote(replacement_name)(unquote_splicing(args))
            end
        end
    end
  end

  def search_override({module, function, arity}, overrides) do
    overrides
    |> Enum.find_value(:error, fn {key, value} ->
      if {module, function, arity} == key do
        {:ok, value}
      else
        false
      end
    end)
  end
end
