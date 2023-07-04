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

  # In v1.15, multiple compile error messages might be shown to the user at once
  # which means this test had to change.
  if Version.compare(System.version(), "1.15.0") == :lt do
    test "Attempting to use a nested named type in a guard raises a CompileError with a descriptive exception message" do
      import ExUnit.CaptureIO

      capture_io(:stderr, fn ->
        assert_raise(
          CompileError,
          ~r"lib/type_check/spec.ex:33: undefined function hidden/0",
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
    end
  else
    test "Attempting to use a nested named type in a guard raises a CompileError with a descriptive message in stderr" do
      import ExUnit.CaptureIO

      stderr_output =
        capture_io(:stderr, fn ->
          assert_raise(
            CompileError,
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

      assert stderr_output =~ ~r"undefined variable \"hidden\""
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
