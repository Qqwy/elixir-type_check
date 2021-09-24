defmodule TypeCheck.ExUnit do
  defmodule Error do
    defexception [:expr, :message, :stacktrace, :exception]
  end

  # TODO use the provided options
  defmacro spectest(module, opts \\ []) do
    req =
      if is_atom(Macro.expand(module, __CALLER__)) do
        quote generated: true, location: :keep do
          require unquote(module)
        end
      end

    tests =
      quote generated: true, location: :keep, bind_quoted: [module: module, opts: opts] do
        env = __ENV__
        for {name, arity} <- module.__type_check__(:specs) do
          spec = TypeCheck.Spec.lookup!(module, name, arity)
          body = TypeCheck.ExUnit.__build_spectest__(module, name, arity, spec)
          # IO.puts(Macro.to_string(body))

          test_name = ExUnit.Case.register_test(env, :spectest, "#{TypeCheck.Inspect.inspect(spec)}", [:spectest])
          def unquote(test_name)(_) do
            import TypeCheck.Protocols.ToStreamData
            require ExUnitProperties
            unquote(body)
          end
        end
      end

    quote generated: true, location: :keep do
      unquote(req)
      unquote(tests)
    end
  end

  @doc false
  def __build_spectest__(module, function_name, arity, spec) do
    {file, line} = spec.location
    # IO.inspect(spec.location)

    generators =
      spec.param_types
      |> Enum.zip(Macro.generate_arguments(arity, module))
      |> Enum.map(fn {type, arg} ->
        quote [generated: true, file: file, line: line] do
          unquote(arg) <- to_gen(unquote(Macro.escape(type)))
        end
      end)

    quote [generated: true] do
        try do
          ExUnitProperties.check all unquote_splicing(generators) do
            unquote(module).unquote(function_name)(unquote_splicing(Macro.generate_arguments(arity, module)))
          end
        rescue
          error ->
            reraise error, [ ({unquote(module), unquote(function_name), unquote(arity), [file: unquote("lib/debug_example.ex"), line: unquote(line)]}) | __STACKTRACE__]
        end
    end
  end
end
