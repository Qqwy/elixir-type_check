defmodule TypeCheck.Internals.Helper do
  @moduledoc false

  def prettyprint_spec(name, ast) do
    IO.puts("#{name} generated:")
    IO.puts("----------------")
    ast |> Macro.to_string() |> Code.format_string!() |> IO.puts()
    IO.puts("----------------")
    IO.puts("")
  end

  def extract_vars_from_ast(ast) do
    {_, names} =
      Macro.postwalk(ast, MapSet.new(), fn ast, names ->
        case ast do
          {name, _meta, context} when is_atom(name) and is_atom(context) ->
            {ast, MapSet.put(names, name)}

          _other ->
            {ast, names}
        end
      end)

    names
  end

  @doc """
  `Macro.Env.fetch_alias/2` was only introduced in Elixir v1.13
  but we need its functionality also on earlier versions.

  So, we emulate it here.
  """
  if Version.compare(System.version(), "1.13.0") == :lt do
    def fetch_alias(env, single_atom) do
      Keyword.fetch(env.aliases, :"Elixir.#{single_atom}")
    end
  else
    def fetch_alias(env, single_atom) do
      Macro.Env.fetch_alias(env, single_atom)
    end
  end

  @doc """
  Module.split/1 raises on non-Elixir module names.
  (atoms or binaries that do not start with `Elixir.')

  This is a safe variant to allow TypeCheck to be used in modules
  that do not follow this convention (like `:my_module_name`),
  which is sometimes done to for instance expose
  an Erlang-ergonomic interface to an Elixir library.
  c.f. [#174](https://github.com/Qqwy/elixir-type_check/issues/174)
  """
  @spec module_split_safe(module | String.t()) :: [String.t(), ...]
  def module_split_safe(module)

  def module_split_safe(module) when is_atom(module) do
    module_split_safe(Atom.to_string(module), _original = module)
  end

  def module_split_safe(module) when is_binary(module) do
    module_split_safe(module, _original = module)
  end

  defp module_split_safe("Elixir." <> name, _original) do
    String.split(name, ".")
  end

  defp module_split_safe(_module, original) do
    original
  end
end
