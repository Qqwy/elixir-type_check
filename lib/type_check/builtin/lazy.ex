defmodule TypeCheck.Builtin.Lazy do
  defstruct [:module, :function, :arguments]

  use TypeCheck
  @type! t :: %TypeCheck.Builtin.Lazy{module: module(), function: atom(), arguments: list(term())}
  @type! problem_tuple :: TypeCheck.TypeError.Formatter.problem_tuple()

  def lazily_expand_type(s) do
    apply(s.module, s.function, s.arguments)
  end

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        type = TypeCheck.Builtin.Lazy.lazily_expand_type(unquote(Macro.escape(s)))
        # Do not inject `param` one step deeper into the check,
        # because that makes dealing with quoting/unquoting difficult.
        lazy_value = unquote(param)
        check_code = TypeCheck.Protocols.ToCheck.to_check(type, Macro.var(:lazy_value, nil))
        {res, _} = Code.eval_quoted(check_code, lazy_value: lazy_value)
        res
      end
    end

    def needs_slow_check?(_) do
      true # Err on the side of caution
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      inspected_arguments =
        s.arguments
        |> Enum.map(&TypeCheck.Protocols.Inspect.inspect(&1, opts))
        |> Inspect.Algebra.fold_doc(fn doc, acc ->
        Inspect.Algebra.concat([doc, ",", acc])
        end)
        # |> Enum.map(&to_string/1)
        # |> Enum.join(", ")

      "lazy("
      |> Inspect.Algebra.concat("#{inspect(s.module)}.#{s.function}(")
      |> Inspect.Algebra.concat(inspected_arguments)
      |> Inspect.Algebra.concat(")")
      |> Inspect.Algebra.color(:builtin_type, opts)

      # "lazy( #{s.module}.#{s.function}(#{inspected_arguments}) )"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        StreamData.bind(StreamData.constant(nil), fn _ ->
          s
          |> TypeCheck.Builtin.Lazy.lazily_expand_type()
          |> TypeCheck.Protocols.ToStreamData.to_gen()
          |> StreamData.scale(fn size -> trunc(:math.log(size + 1)) end) # Since we assume that `lazy` is used for recursive types.
        end)
      end
    end
  end
end
