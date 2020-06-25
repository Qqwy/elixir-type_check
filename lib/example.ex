defmodule EmptyEnv do
  def env() do
    __ENV__
  end
end

defmodule Example do

  @doc "mylist"
  IO.inspect(Module.get_attribute(__MODULE__,:doc))
  @type mylist(element_type) :: list(element_type)
  defmacro mylist(element_type) do
    quote do
      %{type: :list, element_type: unquote(element_type)}
    end
  end

  @typedoc "myint"
  {ln, olddoc} = Module.get_attribute(__MODULE__,:typedoc)
  Module.put_attribute(__MODULE__, :typedoc, {ln, "#{olddoc} new doc!"})
  @type myint :: integer()
  @doc false
  defmacro myint() do
    quote do
      %{type: :integer}
    end
  end

  defmacro intlist() do
    quote do
      mylist(myint())
    end
  end

  defmacro a | b do
    quote do
      %{lhs: unquote(a), rhs: unquote(b), type: :or}
    end
  end

  defmacro literal(val) do
    quote do
      %{type: :literal, value: unquote(Macro.expand(val, EmptyEnv.env()))}
    end
  end

  defmacro lower..upper do
    quote do
      %{type: :range, lower: unquote(lower), upper: unquote(upper)}
    end
  end

  def foo do
    intlist() | literal(0..200) | %{foo: 10}
  end
end

