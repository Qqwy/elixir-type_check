if Code.ensure_loaded?(Credo) do
  defmodule TypeCheck.Credo.Check.Readability.Specs do

  use Credo.Check,
    tags: [:controversial],
    category: :readability,
    param_defaults: [
      include_defp: false
    ],
    explanations: [
      check: """
      Functions, callbacks and macros need typespecs.

      Adding typespecs gives tools like Dialyzer and TypeCheck more information when performing
      checks for type errors in function calls and definitions.
      Typespecs will also be shown in generated documentation,
      and can be a great way to concisely convey how a function should be used.

      Using TypeCheck's `@spec!` syntax which will also enable runtime type-checking:
      (Don't forget to `use TypeCheck` in your module!)

          @spec! sub(integer, integer) :: integer
          def sub(a, b), do: a + b

      If you do not want runtime checks, write a normal `@spec`:

          @spec add(integer, integer) :: integer
          def add(a, b), do: a + b

      Functions with multiple arities need to have a spec defined for each arity:

          @spec! foo(integer) :: boolean
          @spec! foo(integer, integer) :: boolean
          def foo(a), do: a > 0
          def foo(a, b), do: a > b

      The check only considers whether the specification is present, it doesn't
      perform any actual type checking while reading your code.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        include_defp: "Include private functions."
      ]
    ]


  @moduledoc """
  A custom Credo check which supports the `@spec!` syntax.

  NOTE: This module is only compiled
  if you've added `:credo` as a (dev/test) dependency to your app.

  To use this check in your project, make sure you have a `.credo.exs` config file
  (which you can generate with `mix credo gen.config`)
  and make sure to add it to the `:checks` `:enabled` list:

      %{
        configs: [
          %{
            checks: %{
              enabled:
                [
                  {#{__MODULE__}, []},
                  # ...
                ]
                # ...
              }
            # ...
          }
        ]
      }


  This check is an alternative to Credo's own experimental `Credo.Check.Readability.Specs`,
  so be sure to turn that check off.


  ---

  #{@moduledoc}
  """

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    specs = Credo.Code.prewalk(source_file, &find_specs(&1, &2))

    Credo.Code.prewalk(source_file, &traverse(&1, &2, specs, issue_meta))
  end

  defp find_specs(
    {speclike, _, [{:when, _, [{:"::", _, [{name, _, args}, _]}, _]} | _]} = ast,
    specs
  ) when speclike in [:spec, :spec!] do
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs({speclike, _, [{_, _, [{name, _, args} | _]}]} = ast, specs)
  when is_list(args) or is_nil(args) when speclike in [:spec, :spec!] do
    args = with nil <- args, do: []
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs({:impl, _, [impl]} = ast, specs) when impl != false do
    {ast, [:impl | specs]}
  end

  defp find_specs({keyword, meta, [{:when, _, def_ast} | _]}, [:impl | specs])
  when keyword in [:def, :defp] do
    find_specs({keyword, meta, def_ast}, [:impl | specs])
  end

  defp find_specs({keyword, _, [{name, _, nil}, _]} = ast, [:impl | specs])
  when keyword in [:def, :defp] do
    {ast, [{name, 0} | specs]}
  end

  defp find_specs({keyword, _, [{name, _, args}, _]} = ast, [:impl | specs])
  when keyword in [:def, :defp] do
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs(ast, issues) do
    {ast, issues}
  end

  # TODO: consider for experimental check front-loader (ast)
  defp traverse(
    {keyword, meta, [{:when, _, def_ast} | _]},
    issues,
    specs,
    issue_meta
  )
  when keyword in [:def, :defp] do
    traverse({keyword, meta, def_ast}, issues, specs, issue_meta)
  end

  defp traverse(
    {keyword, meta, [{name, _, args} | _]} = ast,
    issues,
    specs,
    issue_meta
  )
  when is_list(args) or is_nil(args) do
    args = with nil <- args, do: []

    if keyword not in enabled_keywords(issue_meta) or {name, length(args)} in specs do
      {ast, issues}
    else
      {ast, [issue_for(issue_meta, meta[:line], name) | issues]}
    end
  end

  defp traverse(ast, issues, _specs, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Functions should have a @spec! or @spec type specification.",
      trigger: trigger,
      line_no: line_no
    )
  end

  defp enabled_keywords(issue_meta) do
    issue_meta
    |> IssueMeta.params()
    |> Params.get(:include_defp, __MODULE__)
    |> case do
         true -> [:def, :defp]
         _ -> [:def]
       end
  end

  end
end
