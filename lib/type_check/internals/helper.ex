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
  def fetch_alias(env, single_atom) do
    if Version.compare(System.version(), "1.13.0") == :lt do
      Keyword.fetch(env.aliases, :"Elixir.#{single_atom}")
    else
      Macro.Env.fetch_alias(env, single_atom)
    end
  end
end
