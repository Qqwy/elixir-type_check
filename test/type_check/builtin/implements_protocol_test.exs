defmodule TypeCheck.Builtin.ImplementsProtocolTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData, only: []

  require TypeCheck
  import TypeCheck.Builtin

  describe "ToStreamData implementation" do

    property "impl(Enumerable) is able to generate enumerables" do
      check all value <- TypeCheck.Protocols.ToStreamData.to_gen(impl(Enumerable)) do
        assert is_integer(Enum.count(value))
      end
    end

    property "impl(Collectable) is able to generate collectables" do
      check all value <- TypeCheck.Protocols.ToStreamData.to_gen(impl(Collectable)) do
        {_initial, collection_fun} = Collectable.into(value)
        assert is_function(collection_fun, 2)
      end
    end

    property "impl(String.Chars) is able to generate anything that indeed can be turned into a string" do
      check all value <- TypeCheck.Protocols.ToStreamData.to_gen(impl(String.Chars)) do
        res = to_string(value)
        assert is_binary(res)
      end
    end

    property "impl(Inspect) is able to generate any inspectable type (essentially anything?)" do
      check all value <- TypeCheck.Protocols.ToStreamData.to_gen(impl(Inspect)), max_runs: 500 do
        res = inspect(value)
        assert is_binary(res)
      end
    end

    test "raises for non-consolidated protocols" do
      defprotocol ThisProtocolIsNotConsolidated do
        def foo(_impl)
      end

      assert_raise(RuntimeError, "values of the type #TypeCheck.Type< impl(TypeCheck.Builtin.ImplementsProtocolTest.ThisProtocolIsNotConsolidated) > can only be generated when the protocol is consolidated.", fn ->
        TypeCheck.Protocols.ToStreamData.to_gen(impl(ThisProtocolIsNotConsolidated))
      end)
    end
  end
end
