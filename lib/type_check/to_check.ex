defmodule TypeCheck.ToCheck do
  @moduledoc """
  Wrapper of the protocol to turn types into type-checks at compile-time.

  Normally there is no need to interact with this module directly.
  """

  @doc """
  Turns a type struct into its type-check AST.
  Usually called at compile-time internally by one of the functions in the `TypeCheck` module.

  Exposed publicly for easier debugging.
  Note that the output of this function might change in new versions to optimize what kinds of checks are generated.
  """
  @spec to_check(TypeCheck.Type.t() , Macro.input()) :: Macro.output()
  def to_check(type_struct, param_ast) do
    if TypeCheck.Protocols.ToCheck.needs_slow_check?(type_struct) do
      IO.inspect("Using slow check for #{inspect(type_struct)}")
      TypeCheck.Protocols.ToCheck.to_check_slow(type_struct, param_ast)
    else
      TypeCheck.Protocols.ToCheck.to_check(type_struct, param_ast)
    end
  end

  @doc """
  True for all types which internally contain function types.

  To handle these properly, we have to unwrap and re-wrap the values during checking,
  so that we can replace the passed-in function with a version of the function that adds the check.

  Exposed publicly for easier debugging.
  Note that the output of this function might change in new versions to optimize what kinds of checks are generated.
  """
  @spec needs_slow_check?(TypeCheck.Type.t()) :: boolean()
  def needs_slow_check?(type_struct) do
    TypeCheck.Protocols.ToCheck.needs_slow_check?(type_struct)
  end
end
