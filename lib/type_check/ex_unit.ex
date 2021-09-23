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

          # quote bind_quoted: [module: module, name: name, arity: arity, spec: spec, env: env, body: body] do
          test_name = ExUnit.Case.register_test(env, :spectest, "#{name}/#{arity}", [:spectest])
          IO.inspect(test_name)
          def unquote(test_name), do: 42
          # end
        end
      end

    [req, tests]
  end

  @doc false
  def __build_spectest__(module, name, arity, spec) do
    quote do
      require ExUnitProperties
      ExUnitProperties.check all {unquote_splicing(Macro.generate_arguments(arity, module))} <- TypeCheck.Protocols.ToStreamData.to_gen(unquote(spec)) do
        unquote(module).unquote(name)(unquote_splicing(Macro.generate_arguments(arity, module)))
      end
    end
  end
end
