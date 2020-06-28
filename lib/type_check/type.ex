defmodule TypeCheck.Type do
  @moduledoc """
  TODO
  """


  defmacro build(type_ast) do
    type_ast
    |> build_unescaped(__CALLER__)
    |> Macro.escape()
  end

  @doc false
  # Building block of macros that take an unexpanded type-AST as input.
  #
  # Transforms `type_ast` (which is expected to be a quoted Elixir AST) into a type value.
  # The result is _not_ escaped
  # assuming that you'd want to do further compile-time work with the type.
  def build_unescaped(type_ast, caller) do
    type_ast = TypeCheck.Internals.PreExpander.rewrite(type_ast, caller)
    {type, []} = Code.eval_quoted(quote do import TypeCheck.Builtin; unquote(type_ast) end, [], caller)
    type
  end
end
