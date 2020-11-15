defmodule TypeCheck.Options.Spec do
  @type t :: %__MODULE__{enabled: boolean(), depth: (non_neg_integer() | :infinity)}
  defstruct [
    enabled: true,
    depth: :infinity
  ]

  def new() do
    %__MODULE__{}
  end

  def new(enum) do
    struct(new(), enum)
  end
end
