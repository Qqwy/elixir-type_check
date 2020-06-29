defmodule TypeCheck.TypeError do
  @moduledoc """
  Exception to be raised when a value is not of the expected type
  """

  defexception [:message, :raw]

  @impl true
  def exception(value) do
    # TODO make humanly readable
    # message = """
    # GOT 'EM
    # #{inspect(value)}
    # """
    message = TypeCheck.TypeError.DefaultFormatter.format_wrap(value)

    %__MODULE__{message: message, raw: value}
  end
end
