defprotocol TypeCheck.Protocols.ToCheck do
  @moduledoc false

  @spec to_check(t, Macro.input()) :: Macro.output()
  def to_check(type, param_ast)

  @spec needs_slow_check?(t) :: boolean()
  def needs_slow_check?(type)

  @spec to_check_slow(t, Macro.input()) :: Macro.output()
  def to_check_slow(type, param_ast)
end
