defmodule TypeCheck.OptionsTest do
  use ExUnit.Case
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
end
