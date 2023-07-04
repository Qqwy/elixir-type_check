defmodule TypeCheck.Builtin.NamedTypeTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData, only: []
  use TypeCheck

  defmodule Example do
    use TypeCheck

    @opaque! secret() :: (fancy :: binary() when is_binary(fancy))
    @type! known :: (%{a: number(), b: secret()} when is_binary(fancy))

    # @spec! foo() :: known()
    # def foo() do
    # end
  end

  test "Attempting to use a nested named type in a guard raises a CompileError" do
    import ExUnit.CaptureIO

    error = capture_io(:stderr, fn ->
      assert_raise(
        CompileError,
        # ~r"lib/type_check/spec.ex:30: undefined function hidden/0",
        fn ->
          defmodule BadExample do
            use TypeCheck

            @opaque! nested() :: hidden :: binary()
            @type! known :: (%{a: number(), b: nested()} when is_binary(hidden))

            @spec! example(known()) :: known()
            def example(val) do
              val
            end
          end
        end
      )
    end)
    if Version.compare(System.version() , "1.15.0") == :lt do
      assert error =~ ~r"lib/type_check/spec.ex:30: undefined function hidden/0"
    else
      assert error =~ ~r"undefined variable \"hidden\""
    end
  end

  test "Using a local named type works" do
    defmodule GoodExample do
      use TypeCheck
      @opaque! known :: (%{a: number(), b: nothidden :: binary()} when is_binary(nothidden))

      @spec! example(known()) :: known()
      def example(val) do
        val
      end
    end
  end
end
