defmodule TypeCheck.OptionsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias TypeCheck.Options

  doctest Options

  describe "overrides" do
    property "any list of MFAs is allowed" do
      overrides_gen = StreamData.list_of(mfa_or_capture_override_gen())

      check all overrides <- overrides_gen do
        options = TypeCheck.Options.new(overrides: overrides)

        assert is_list(options.overrides)
      end
    end

    test "overrides are respected by the macros" do
      assert OverrideExample.times_two(42) == 84
      assert_raise(TypeCheck.TypeError, fn ->
        OverrideExample.times_two("a beautiful string")
      end)
    end

    test "an TypeCheck.TypeError is raised on an improper overrides list" do
      assert_raise(TypeCheck.TypeError, fn ->
        TypeCheck.Options.new(overrides: [{OverrideExample.Original, :t, 0}])
      end)
    end
  end

  # Ensure either original and/or override
  # might use either the mfa or the function capture syntax.
  defp mfa_or_capture_override_gen do
    mfa_override_gen()
    |> StreamData.bind(fn {original, override} ->
      {mfa_or_capture_gen(original), mfa_or_capture_gen(override)}
    end)
  end

  # Alter an mfa to be a capture 50% of the time
  defp mfa_or_capture_gen(mfa) do
    [mfa, capture_from_mfa(mfa)]
    |> Enum.map(&StreamData.constant/1)
    |> StreamData.one_of
  end

  # Ensure original and override have same arity
  defp mfa_override_gen() do
    {StreamData.atom(:alias), StreamData.atom(:alphanumeric), StreamData.atom(:alias), StreamData.atom(:alphanumeric), StreamData.integer(0..255)}
    |> StreamData.map(fn {m1, f1, m2, f2, a} ->
      {{m1, f1, a}, {m2, f2, a}}
    end)

  end

  defp capture_from_mfa({m, f, a}) do
    Function.capture(m, f, a)
  end

  describe "debug: true" do
    import StreamData, only: [], warn: false
    import ExUnit.CaptureIO

	  test "works on TypeCheck.conforms" do
      output =  capture_io(fn ->
        Code.eval_quoted(
          quote do
            require TypeCheck
            import TypeCheck.Builtin
            TypeCheck.conforms(42, integer(), debug: true)
          end)
      end)
      assert "TypeCheck.conforms(42, #TypeCheck.Type< integer() >, [debug: true]) generated:\n----------------\n" <> _rest = output
    end

	  test "works on TypeCheck.conforms?" do
      output =  capture_io(fn ->
        Code.eval_quoted(
          quote do
            require TypeCheck
            import TypeCheck.Builtin
            TypeCheck.conforms?(42, integer(), debug: true)
          end)
      end)
      assert "TypeCheck.conforms?(42, #TypeCheck.Type< integer() >, [debug: true]) generated:\n----------------\n" <> _rest = output
    end

	  test "works on TypeCheck.conforms!" do
      output =  capture_io(fn ->
        Code.eval_quoted(
          quote do
            require TypeCheck
            import TypeCheck.Builtin
            TypeCheck.conforms!(42, integer(), debug: true)
          end)
      end)
      assert "TypeCheck.conforms!(42, #TypeCheck.Type< integer() >, [debug: true]) generated:\n----------------\n" <> _rest = output
    end

	  test "works on TypeCheck.dynamic_conforms" do
      output =  capture_io(fn ->
        import TypeCheck.Builtin
        TypeCheck.dynamic_conforms(42, integer(), debug: true)
      end)
      assert "TypeCheck.dynamic_conforms(42, #TypeCheck.Type< integer() >, [debug: true]) generated:\n----------------\n" <> _rest = output
    end

    test "works on @spec!" do
      output = capture_io(fn ->
        defmodule TypeCheckDebugSpec do
          use TypeCheck, debug: true

          @spec! foo(integer()) :: binary()
          def foo(val) do
            to_string(val)
          end
        end
      end)

      assert "TypeCheck.Macros @spec generated:\n----------------\n" <> _rest = output
    end
  end

  describe "enable_runtime_checks: false" do
    test "functions now accept malformed data" do
      defmodule EnableRuntimeChecksExample do
        use TypeCheck, enable_runtime_checks: false
        @spec! foo(number()) :: String.t()
        def foo(val) do
          to_string(val)
        end
      end

      not_a_number = "Hello"
      assert "Hello" == EnableRuntimeChecksExample.foo(not_a_number)
    end

    test "functions now can return malformed data" do
      defmodule EnableRuntimeChecksExample2 do
        use TypeCheck, enable_runtime_checks: false
        @spec! broken(number()) :: String.t()
        def broken(val) do
          false
        end
      end

      assert false == EnableRuntimeChecksExample2.broken(42)
    end
  end
end
