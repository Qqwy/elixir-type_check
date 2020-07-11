defprotocol TypeCheck.Protocols.ToCheck do
  @moduledoc false

  def to_check(val, param_ast)
  def simple?(val)
end
