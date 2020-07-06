defmodule TypeCheck.Builtin.Lazy do
  defstruct [:module, :function, :arguments]

  def lazily_expand_type(s) do
    apply(s.module, s.function, s.arguments)
  end

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        type = TypeCheck.Builtin.Lazy.lazily_expand_type(unquote(Macro.escape(s)))
        # Do not inject `param` one step deeper into the check,
        # because that makes dealing with quoting/unquoting difficult.
        lazy_value = unquote(param)
        check_code = TypeCheck.Protocols.ToCheck.to_check(type, Macro.var(:lazy_value, nil))
        {res, _} = Code.eval_quoted(check_code, [lazy_value: lazy_value])
        res
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      inspected_arguments = Enum.map(s.arguments, &TypeCheck.Protocols.Inspect.inspect(&1, opts))
      "lazy( #{s.module}.#{s.function}(#{inspected_arguments}) )"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        StreamData.bind(StreamData.constant(nil), fn _ ->
          s
          |>TypeCheck.Builtin.Lazy.lazily_expand_type
          |> TypeCheck.Protocols.ToStreamData.to_gen
        end)
      end
    end
  end
end
