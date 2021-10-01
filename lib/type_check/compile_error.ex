defmodule TypeCheck.CompileError do
  @moduledoc """
  Raised when during compilation of types or specifications,
  an irrecoverable error occurs.
  """
  defexception [:message]
end
