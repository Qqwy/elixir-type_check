defmodule TypeCheck.ExUnit do
  @moduledoc """
  Provides macros for 'spectests': spec-automated property-testing.

  The core macro exposed by this module is `spectest/2`, which
  will will check for all function-specs in the given module,
  whether those functions correctly follow the spec.

  To use this functionality, add `use TypeCheck.ExUnit` to your testing module.


  Currently, spectesting uses `StreamData` under the hood.
  This means that to use the `spectest` functionality,
  you need to add the `:stream_data` dependency to your application
  (it is an optional dependency of `TypeCheck`.)

  In the future, support for other property-generating libraries might be added.


  ### What is a spectest?

  A 'function-specification test' is a property-based test in which
  we check whether the function adheres to its _invariants_
  (also known as the function's _contract_ or _preconditions and postconditions_).

  We generate a large amount of possible function inputs,
  and for each of these, check whether the function:

  - Does not raise an exception.
  - Returns a result that type-checks against the spec's return-type.
    (To be precise, if an incorrect result is returned, the function
    is wrapped in will end up raising an exception for this.)

  While `@spec!`s themselves ensure that callers do not mis-use your function,
  a `spectest` ensures¹ that the function itself is working correctly.

  Spectests are given its own test-category in ExUnit, for easier recognition
  (Just like 'doctests' and 'properties' are different from normal tests, so are 'spectests'.)

  ¹: Because of the nature of property-based testing, we can never know for 100% sure
  that a function is correct. However, with every new randomly-generated
  test-case, the level of confidence grows a little. So while we
  can never by _fully_ sure, we are able to get asymptotically close to it.

  """

  @doc """
  Sets up a testing module for spectesting.

  Not normally invoked directly, but rather by calling `use TypeCheck.ExUnit`.

  Currently does not accept any options, but this might change in the future.
  """
  defmacro __using__(_opts) do
    quote do
      import TypeCheck.ExUnit
    end
  end

  @doc """
  Tests the functions in `module` against their `@spec!`s.

  `spectest` will look at all functions which have a TypeCheck spec in `module`,
  and will for each of them run a 'spectest'.
  See the module documentation for more information on spectests in general.

  ### Examples

  ```
  defmodule MyModuleTest do
    use ExUnit.Case, async: true
    use TypeCheck.ExUnit

    # Test all functions that have `@spec!`s in `MyModule`
    spectest MyModule

    # Test all functions that have `@spec!`s in `MyOtherModule`,
    # except `MyOtherModule.bar/2` and `MyOtherModule.baz/0`
    spectest MyOtherModule, except: [{:bar, 2}, {:baz, 0}]

    # Test only `OneMoreModule.foo/2` and `MyOtherModule.qux/0`
    spectest OneMoreModule, only: [{:foo, 2}, {:qux, 0}]
  end
  ```

  ### Options

  - `:except`
  - `:only`
  - `:initial_seed`
  - `:generator`

  #### Except and Only

  By default, all functions in the module (that have an associated `@spec!`) will be tested.

  If any of them need to be skipped, you can add them as a list of `{name, arity}`-pairs under `except:`.

  If instead of excluding a few functions, you want to _only_ test a small subset of functions, you can add them as `{name, arity}`-pairs under `only:`.

  #### Initial seed

  The `:initial_seed`-option can be used to seed the property-generation.
  It expects an integer value.
  This option is passed on to the generator automatically (without requiring the usage of generator-specific options).
  By default, the seed of the ExUnit configuration is used (which by default differs every test run).

  #### Generator

  The `generator:` option expects either the name of a property-testing library, or a `{name, options}`-tuple.
  (If only the name is specified, this is a shorthand for `{Name, []}`).

  For now, only `StreamData` is supported, and this is its default value. If you want to pass extra options to the library, the notation `{StreamData, list_of_options}` can be passed.
  For the list of options supported by StreamData, see `StreamData.check_all/3`.

  """
  if Code.ensure_loaded?(StreamData) do
    defmacro spectest(module, options \\ []) do
      do_spectest(module, options, __CALLER__)
    end
  else
    defmacro spectest(_module, _options \\ []) do
      raise ArgumentError, """
      `spectest/2` depends on the optional library `:stream_data`.
      To use this functionality, add `:stream_data` to your application's deps.
      """
    end
  end

  defp do_spectest(module, options, caller) do
    req =
      if is_atom(Macro.expand(module, caller)) do
        quote generated: true, location: :keep do
          require unquote(module)
        end
      end

    tests =
      quote generated: true, location: :keep, bind_quoted: [module: module, options: options] do
        initial_seed =
          case Keyword.get(options, :initial_seed, ExUnit.configuration()[:seed]) do
            seed when is_integer(seed) ->
              seed

            other ->
              raise ArgumentError,
                    "expected :initial_seed to be an integer, got: #{inspect(other)}"
          end

        generator_options =
          case options[:generator] do
            nil -> []
            StreamData -> []
            {StreamData, opts} when is_list(opts) -> opts
          end

        generator_options =
          generator_options ++ [initial_seed: Macro.escape({0, 0, initial_seed})]

        env = __ENV__
        exposed_specs = module.__type_check__(:specs)
        specs = (options[:only] || exposed_specs) -- (options[:except] || [])

        for {name, arity} <- specs do
          spec = TypeCheck.Spec.lookup!(module, name, arity)
          body = TypeCheck.ExUnit.__build_spectest__(module, name, arity, spec, generator_options)

          test_name =
            ExUnit.Case.register_test(env, :spectest, "#{TypeCheck.Inspect.inspect(spec)}", [
              :spectest
            ])

          def unquote(test_name)(_) do
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
  def __build_spectest__(module, function_name, arity, spec, generator_options) do
    quote generated: true do
      generator_options = unquote(generator_options)

      generator = TypeCheck.Type.StreamData.to_gen(unquote(Macro.escape(spec)))

      result =
        StreamData.check_all(generator, generator_options, fn unquote(
                                                                Macro.generate_arguments(
                                                                  arity,
                                                                  module
                                                                )
                                                              ) ->
          try do
            unquote(module).unquote(function_name)(
              unquote_splicing(Macro.generate_arguments(arity, module))
            )

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
          shrunk_params =
            metadata.shrunk_failure.generated_values |> Enum.map(&inspect/1) |> Enum.join(", ")

          message = """
          Spectest failed (after #{metadata.successful_runs} successful runs)

          Input: #{inspect(unquote(module))}.#{unquote(function_name)}(#{shrunk_params})

          #{Exception.format(:error, metadata.shrunk_failure.exception)}
          """

          problem = [message: message, expr: unquote(Macro.escape(spec))]

          reraise ExUnit.AssertionError, problem, metadata.shrunk_failure.stacktrace

        {:ok, _} ->
          :ok
      end
    end
  end
end
