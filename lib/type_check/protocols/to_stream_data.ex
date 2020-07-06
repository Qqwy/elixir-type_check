if Code.ensure_loaded?(StreamData) do
  defprotocol TypeCheck.Protocols.ToStreamData do
    @moduledoc false

    def to_gen(s)
  end
end
