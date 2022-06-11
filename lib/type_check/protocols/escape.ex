defprotocol TypeCheck.Protocols.Escape do
  @moduledoc false
  # Escaping of structs.
  # Instead of always using `Macro.escape`,
  # Try to be slightly more clever to make sure compile-time AST
  # does not become super large

  @fallback_to_any true

  @spec escape(TypeCheck.Type.t()) :: Macro.t()
  def escape(val)

end

defimpl TypeCheck.Protocols.Escape, for: Any do
  def escape(val) do
    val
  end
end
