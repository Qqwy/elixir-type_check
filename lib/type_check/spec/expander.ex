defmodule TypeCheck.Spec.Expander do
  @moduledoc false
  # Expands a typespec-AST to its symbolic nested-structs form


  # Variable name (or function call without parentheses)
  def expand(orig = {name, _, atom}, expanded_types, unexpanded_types) when is_atom(name) and is_atom(atom) do
    IO.inspect(orig, label: :expand_var)
    # Look up other types in scope.
    # Falling back to the Builtin module's exports.

    cond do
      expanded_types[name] ->
        expanded_types[name]
      unexpanded_types[name] ->
        # TODO keep track of the results of this
        # maybe put them in a module attribute temporarily or something?
        res = expand(unexpanded_types[name], expanded_types, unexpanded_types)
        res
      {name, 0} in TypeCheck.Spec.Builtin.__info__(:functions) ->
        apply(TypeCheck.Spec.Builtin, name, [])
      true ->
        # Leave as-is, Elixir will raise a descriptive error for us
        orig
    end
  end

  # Function call
  def expand(orig = {name, meta, args}, expanded_types, unexpanded_types) when is_atom(name) and is_list(args) do
    IO.inspect(orig, label: :expand_fun)
    expanded_args = expand(args, expanded_types, unexpanded_types)
    cond do
      {name, length(expanded_args)} in TypeCheck.Spec.Builtin.__info__(:functions) ->
        apply(TypeCheck.Spec.Builtin, name, expanded_args)
      true ->
        # Leave as-is, Elixir will raise a descriptive error for us
        {name, meta, args}
    end
  end

  def expand(other, e, u) do
    IO.inspect(other, label: :expand_other)
    other
  end
end
