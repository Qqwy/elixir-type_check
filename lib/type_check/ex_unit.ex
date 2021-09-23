defmodule TypeCheck.ExUnit do
  # TODO use opts
  defmacro spectest(module, opts \\ []) do
    req =
      if is_atom(Macro.expand(module, __CALLER__)) do
        quote do
          require unquote(module)
        end
      end

    tests =
      quote location: :keep, bind_quoted: [module: module, opts: opts] do
        env = __ENV__
        for {name, arity} <- module.__type_check__(:specs) do
          spec = TypeCheck.Spec.lookup!(module, name, arity)
          body = TypeCheck.ExUnit.__build_spectest__(module, name, arity, spec)
          IO.puts(Macro.to_string(body))

          test_name = ExUnit.Case.register_test(env, :spectest, "#{TypeCheck.Inspect.inspect(spec)}", [:spectest])
          def unquote(test_name)(_) do
            import TypeCheck.Protocols.ToStreamData
            unquote(body)
          end
        end
      end

    quote do
      unquote(req)
      unquote(tests)
    end
  end

  @doc false
  def __build_spectest__(module, name, arity, spec) do
    generators =
      spec.param_types
      # |> Enum.map(&TypeCheck.Protocols.ToStreamData.to_gen/1)
      |> Enum.zip(Macro.generate_arguments(arity, module))
      |> Enum.map(fn {type, arg} ->
      quote do
        unquote(arg) <- to_gen(unquote(Macro.escape(type)))
      end
      end)

    quote do
      require ExUnitProperties
      # arguments_generator = TypeCheck.Protocols.ToStreamData.to_gen(unquote(Macro.escape(spec)))
      # ExUnitProperties.check all {unquote_splicing(Macro.generate_arguments(arity, module))} <- arguments_generator do
      #   unquote(module).unquote(name)(unquote_splicing(Macro.generate_arguments(arity, module)))
      # end
      ExUnitProperties.check all unquote_splicing(generators) do
        unquote(module).unquote(name)(unquote_splicing(Macro.generate_arguments(arity, module)))
      end
    end
  end
end
