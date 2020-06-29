if Code.ensure_loaded?(StreamData) do
  defprotocol TypeCheck.Protocols.ToStreamData do
    def to_gen(s)
  end
end
