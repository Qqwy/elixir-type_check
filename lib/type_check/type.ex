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
  def build_unescaped(type_ast, caller, add_typecheck_module \\ false) do
    type_ast = TypeCheck.Internals.PreExpander.rewrite(type_ast, caller)
    {type, []} = if add_typecheck_module do
        Code.eval_quoted(
          quote do
            import TypeCheck.Builtin
            import __MODULE__.TypeCheck
            unquote(type_ast)
          end,
          [], caller)
    else
      {type, []} =
        Code.eval_quoted(
          quote do
            import TypeCheck.Builtin;
            unquote(type_ast)
          end,
          [], caller)
    end
    type
  end


  if Code.ensure_loaded?(StreamData) do
    def stream_data_gen(type) do
      TypeCheck.Protocols.ToStreamData.to_gen(type)
    end
  end
end
