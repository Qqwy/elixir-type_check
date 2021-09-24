defmodule TypeCheck.ExUnit do
  defmodule Error do
    defexception [:expr, :message, :stacktrace, :exception]
  end

  # TODO use the provided options
  defmacro spectest(module, options \\ []) do
    req =
    if is_atom(Macro.expand(module, __CALLER__)) do
      quote generated: true, location: :keep do
        require unquote(module)
      end
    end


    initial_seed =
      case Keyword.get(options, :initial_seed, ExUnit.configuration()[:seed]) do
        seed when is_integer(seed) ->
          # Macro.escape({0, 0, seed})
          seed

        other ->
          raise ArgumentError, "expected :initial_seed to be an integer, got: #{inspect(other)}"
      end

    options = options |> Keyword.put(:initial_seed, initial_seed)

    tests =
      quote generated: true, location: :keep, bind_quoted: [module: module, options: options] do
      env = __ENV__
      for {name, arity} <- module.__type_check__(:specs) do
        spec = TypeCheck.Spec.lookup!(module, name, arity)
        body = TypeCheck.ExUnit.__build_spectest__(module, name, arity, spec, options)
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
  def __build_spectest__(module, function_name, arity, spec, options) do
    # {file, line} = spec.location
    # IO.inspect(spec.location)

    # generators =
    #   spec.param_types
    #   |> Enum.zip(Macro.generate_arguments(arity, module))
    #   |> Enum.map(fn {type, arg} ->
    #     quote [generated: true, file: file, line: line] do
    #       unquote(arg) <- to_gen(unquote(Macro.escape(type)))
    #     end
    #   end)


    quote [generated: true] do
      # ExUnitProperties.check all unquote_splicing(generators) do
      #   unquote(module).unquote(function_name)(unquote_splicing(Macro.generate_arguments(arity, module)))
      # end
      options = unquote(options)
      initial_seed = {0, 0, options[:initial_seed]}


      generator = TypeCheck.Protocols.ToStreamData.to_gen(unquote(Macro.escape(spec)))
      result = StreamData.check_all(generator, [initial_seed: initial_seed], fn unquote(Macro.generate_arguments(arity, module)) ->
        try do
          unquote(module).unquote(function_name)(unquote_splicing(Macro.generate_arguments(arity, module)))
          {:ok, unquote(Macro.generate_arguments(arity, module))}
        rescue
          exception ->
            result = %{
          exception: exception,
          stacktrace: __STACKTRACE__,
          generated_values: unquote(Macro.generate_arguments(arity, module))
        }
          {:error, result}
        end
      end)

      case result do
        {:error, metadata} ->
          shrunk_params = metadata.shrunk_failure.generated_values |> Enum.map(&inspect/1) |> Enum.join(", ")
          message =
            """
            Spectest failed (after #{metadata.successful_runs} successful runs)

            Input: #{inspect(unquote(module))}.#{unquote(function_name)}(#{shrunk_params})

            #{Exception.format(:error, metadata.shrunk_failure.exception)}
            """
          problem =
            [message: message,
             expr: unquote(Macro.escape(spec))
            ]

          reraise ExUnit.AssertionError, problem, metadata.shrunk_failure.stacktrace
        {:ok, _} -> :ok
      end
    end
  end
end
