defmodule TypeCheck.DefaultOverrides do
  @moduledoc """
  Contains a many common types that can be used as overrides for Elixir's standard library's 'Remote Types'.

  This module complements `TypeCheck.Builtin`, contains all 'built-in' types of Elixir.

  Implementing TypeSpecs for all types of Elixir's standard library is a work-in-progress.
  Some TypeCheck-versions of the types are a little more general than the original version,
  to make up for functionality in TypeCheck which does not exist yet.

  Simply put, this means that you will never get a 'false positive' (a correct value not being accepted by a function),
  but in very rare cases you might get a 'false negative' (an improper value passing the type-check.)

  """

  Code.ensure_compiled(TypeCheck)
  use TypeCheck

  @elixir_modules ~w[
    Access
    Agent
    Application
    Calendar
    Calendar.ISO
    Calendar.TimeZoneDatabase
    Code
    Code.Fragment
    Collectable
    Config.Provider
    Date
    Date.Range
    DateTime
    DynamicSupervisor
    Enum
    Enumerable
    Exception
    File
    File.Stat
    File.Stream
    Float
    Function
    GenServer
    Inspect
    Inspect.Algebra
    Inspect.Opts
    IO
    IO.ANSI
    IO.Stream
    Kernel.ParallelCompiler
    Keyword
    List.Chars
    Macro
    Map
    MapSet
    Module
    NaiveDateTime
    Node
    OptionParser
    Path
    Port
    Process
    Range
    Regex
    Registry
    Stream
    String
    String.Chars
    Supervisor
    System
    Task
    Time
    URI
    Version
    Version.Requirement
  ]a

  @erlang_modules ~w[
    Erlang.Binary
    Erlang.Inet
    Erlang.Calendar
  ]a

  for module <- @erlang_modules do
    Code.ensure_compiled(Elixir.Module.concat(__MODULE__, module))
  end

  for module <- @elixir_modules do
    Code.ensure_compiled(Elixir.Module.concat(__MODULE__, module))
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
    |> String.downcase()
    |> String.to_existing_atom()
  end
end
