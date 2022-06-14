defprotocol TypeCheck.Protocols.Escape do
  @moduledoc false
  # Escaping of structs.
  # c.f. TypeCheck.Internals.Escaper for more info

  @fallback_to_any true

  @spec escape(TypeCheck.Type.t()) :: Macro.t()
  def escape(val)

end

defimpl TypeCheck.Protocols.Escape, for: Any do
  def escape(val) do
    val
  end
end
