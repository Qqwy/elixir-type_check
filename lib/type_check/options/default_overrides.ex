defmodule TypeCheck.Options.DefaultOverrides do
  @moduledoc """
  Contains a many common types that can be used as overrides for Elixir's standard library types.
  """

  Code.ensure_compiled!(TypeCheck)
  use TypeCheck

  @elixir_modules ~w[
    Access
    Calendar
    Calendar.ISO
    Collectable
    Date
    Date.Range
    Enum
    Enumerable
    Exception
    File
    File.Stat
    File.Stream
    Float
    Function
    Inspect
    IO
    Keyword
    Map
    MapSet
    Module
    NaiveDateTime
    Range
    Regex
    Stream
    String
    Time
    URI
    Version
    Version.Requirement
  ]a

  @erlang_modules ~w[
    Erlang.Binary
    Erlang.Inet
  ]a

  for module <- @elixir_modules do
    Code.ensure_compiled!(Elixir.Module.concat(__MODULE__, module))
  end

  for module <- @erlang_modules do
    Code.ensure_compiled!(Elixir.Module.concat(__MODULE__, module))
  end


  @doc """
  Lists all overridden types in {module, function, arity} format.
  """
  @spec default_overrides :: list(mfa())
  def default_overrides do
    elixir_overrides = Elixir.Enum.flat_map(@elixir_modules, &build_overrides/1)

    erlang_overrides = Elixir.Enum.flat_map(@erlang_modules, &build_erlang_overrides/1)

    elixir_overrides ++ erlang_overrides
  end

  defp build_overrides(module) do
    replacement_module = Elixir.Module.concat(__MODULE__, module)
    replacement_module.__type_check__(:types)
    |> Elixir.Enum.map(fn {type, arity} ->
      orig = {Elixir.Module.concat(Elixir, module), type, arity}
      new = {Elixir.Module.concat(__MODULE__, module), type, arity}
      {orig, new}
    end)
  end

  defp build_erlang_overrides(module) do
    replacement_module = Elixir.Module.concat(__MODULE__, module)
    replacement_module.__type_check__(:types)
    |> Elixir.Enum.map(fn {type, arity} ->
      erlang_module = semimodule_to_erlang_module(module)

      orig = {erlang_module, type, arity}
      new = {Elixir.Module.concat(__MODULE__, module), type, arity}
      {orig, new}
    end)
  end

  defp semimodule_to_erlang_module(semimodule) do
    "Erlang." <> name = Atom.to_string(semimodule)

    name
    |> String.downcase
    |> String.to_existing_atom
  end
end
