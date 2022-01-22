defmodule ExKeymap.KeymapItem do
  use TypeCheck
  defstruct [:item_name, :help, :fun]

  @type! t :: %__MODULE__{
    item_name: String.t(),
    fun: (-> any()),
    help: String.t() | nil
  }

  @spec! new(String.t(), (-> any()), String.t() | nil) :: t()
  def new(item_name, fun, help \\ nil) do
    %__MODULE__{
      item_name: item_name,
      fun: fun,
      help: help
    }
  end
end
