defmodule TypeCheck.Internals.Escaper do
  @moduledoc false
  # Abbreviate types when inlining their literal structs
  # in compiled code
  # to make sure that this compiled code is not ridiculously large
  # (c.f. #110)

  def escape(val) do
    val
    |> TypeCheck.Protocols.Escape.escape()
    |> Macro.escape(unquote: true)
  end
end
