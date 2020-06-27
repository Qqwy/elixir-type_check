defmodule TypeCheck.Builtin.Range do
  defstruct [:lower, :higher]


  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(%{lower: lower, higher: higher}, param) do
      quote do
        case unquote(param) do
          x when x in range ->
            :ok
          _ ->
            {:error, {TypeCheck.Builtin.Float, :not_a_float, %{}, unquote(param)}}
        end
      end
    end
  end

end
