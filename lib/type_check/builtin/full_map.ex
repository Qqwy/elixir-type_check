defmodule TypeCheck.Builtin.FullMap do
  defstruct [:required_kvs, :optional_kv]

  use TypeCheck
  @opaque! t :: %__MODULE__{required_kvs: list({TypeCheck.Type.t(), TypeCheck.Type.t()}), optional_kv: {TypeCheck.Type.t(), TypeCheck.Type.t()}}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      raise "TODO"
    end
  end
end
