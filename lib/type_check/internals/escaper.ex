defmodule TypeCheck.Internals.Escaper do
  @moduledoc false
  # Abbreviate types when inlining their literal structs
  # in compiled code
  # to make sure that this compiled code is not ridiculously large
  # (c.f. #110)

  def escape(val) do
    val
    |> TypeCheck.Protocols.Escape.escape()
    |> Macro.escape(unquote: :true)
  end

  # def escape(val) do
  #   case do_escape(val) do
  #     map = %{} ->
  #       Macro.escape(map, unquote: true)
  #     other ->
  #       other
  #   end
  # end

  # def do_escape(s = %TypeCheck.Builtin.NamedType{}) do
  #   case s do
  #     %{called_as: {module, function, args}, type_kind: kind} when kind in [:type, :opaque] ->
  #       escaped_args = args
  #       |> do_escape()
  #       |> Macro.escape()

  #       quote do
  #         unquote(module).unquote(function)(unquote_splicing(escaped_args))
  #       end
  #     other -> other
  #   end
  # end

  # def do_escape(other_struct_or_map = %{}) do
  #   :maps.map(fn _key, value -> do_escape(value) end, other_struct_or_map)
  # end

  # def do_escape(list) when is_list(list) do
  #   Enum.map(list, fn value -> do_escape(value) end)
  # end

  # def do_escape(other) do
  #   other
  # end
end
