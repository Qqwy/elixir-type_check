defmodule TypeCheck.Builtin do
  defmacro integer() do
    quote location: :keep do
      %{type: :integer}
    end
  end

  defmacro list(a) do
    IO.inspect(a, label: :list)
    quote location: :keep do
      %{type: :list, element_type: unquote(a)}
    end
  end
end
