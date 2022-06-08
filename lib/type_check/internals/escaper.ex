defmodule TypeCheck.Internals.Escaper do
  @moduledoc false
  # Abbreviate types when inlining their literal structs
  # in compiled code
  # to make sure that this compiled code is not ridiculously large
  # (c.f. #110)

  def escape(s = %TypeCheck.Builtin.NamedType{}) do
    case s do
      %{called_as: {module, function, args}, type_kind: kind} when kind in [:type, :opaque] ->
        quote do
          unquote(module).unquote(function)(unquote_splicing(args))
        end
      other -> Macro.escape(other)
    end
  end

  def escape(other_struct_or_map = %{}) do
    Enum.map(other_struct_or_map, fn {key, value} ->
      {key, escape(value)}
    end)
    |> Enum.into(%{})
  end

  def escape(list) when is_list(list) do
    Enum.map(list, fn value -> escape(value) end)
  end

  def escape(other) do
    Macro.escape(other)
  end
end
