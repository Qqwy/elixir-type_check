defmodule TypeCheck.Spec.Expander do
  @moduledoc false
  # Expands a typespec-AST to its symbolic nested-structs form

  def expand(name, orig, env, top_level_def \\ nil) do
    top_level_def = top_level_def || orig
    res = do_expand(orig, env, Macro.to_string(orig))
    Module.put_attribute(env.module, TypeCheck.Spec.Expanded, {name, res})
    res
  end

  def do_expand(orig = [{:->, meta, args}], env, top_level_def) do
    raise "Currently, TypeCheck does not support types with `->`. Support will hopefully be added in the future."
  end

  # Variable name (or function call without parentheses)
  def do_expand(orig = {name, _, atom}, env, top_level_def) when is_atom(name) and is_atom(atom) do
    IO.inspect(orig, label: :expand_var)
    # Look up other types in scope.
    # Falling back to the Builtin module's exports.
    cond do
      already_expanded = Module.get_attribute(env.module, TypeCheck.Spec.Expanded)[:"#{name}/0"] ->
        already_expanded.type
      Module.get_attribute(env.module, TypeCheck.Spec.BeingExpanded)[:"#{name}/0"] ->
        raise "Expansion loop detected: Asked to expand #{name} while expanding #{top_level_def}"
      unexpanded = Module.get_attribute(env.module, TypeCheck.Spec.Unexpanded)[:"#{name}/0"] ->
        expand(name, unexpanded.type, env, top_level_def)
      {name, 0} in TypeCheck.Spec.Builtin.__info__(:functions) ->
        apply(TypeCheck.Spec.Builtin, name, [])
      true ->
        # Leave as-is, Elixir will raise a descriptive error for us
        orig
    end
  end

  # Function call
  def do_expand(orig = {name, meta, args}, env, top_level_def) when is_atom(name) and is_list(args) do
    IO.inspect(orig, label: :expand_fun)

    expanded_args =
      args
      |> Enum.map(fn arg -> expand(extract_name(arg), arg, env, top_level_def) end)
    arity = length expanded_args
    cond do
      already_expanded = Module.get_attribute(env.module, TypeCheck.Spec.Expanded)[:"#{name}/#{arity}"] ->
        # TODO arg passing
        already_expanded.type
      Module.get_attribute(env.module, TypeCheck.Spec.BeingExpanded)[:"#{name}/#{arity}"] ->
        raise "Expansion loop detected: Asked to expand #{name} while expanding #{top_level_def}"
      unexpanded = Module.get_attribute(env.module, TypeCheck.Spec.Unexpanded)[:"#{name}/#{arity}"] ->
        # TODO arg passing
        expand(name, unexpanded.type, env, top_level_def)
      {name, arity} in TypeCheck.Spec.Builtin.__info__(:functions) ->
        apply(TypeCheck.Spec.Builtin, name, expanded_args)
      true ->
        # Leave as-is, Elixir will raise a descriptive error for us
        {name, meta, args}
    end
  end

  def do_expand(other, e, u) do
    IO.inspect({other, e, u}, label: :expand_other)
    other
  end

  def extract_name(ast) do
    with :error <- extract_var_name(ast),
         :error <- extract_fun_name(ast) do
      raise "Expected variable or function call , but found #{Macro.to_string(ast)}"
    else
      {:ok, res} -> res
    end
  end


  def extract_var_name({name, _, module}) when is_atom(name) and is_atom(module), do: {:ok, name}
  def extract_var_name(_), do: :error


  def extract_fun_name({name, _, module}) when is_atom(name) and is_list(module), do: {:ok, name}
  def extract_fun_name(_), do: :error
end
