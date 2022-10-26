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
end
