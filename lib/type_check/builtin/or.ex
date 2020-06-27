defmodule TypeCheck.Builtin.Or do
  defstruct [:left, :right]

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(%{left: left, right: right}, param) do
      left_check = TypeCheck.Protocols.ToCheck.to_check(left, param)
      right_check = TypeCheck.Protocols.ToCheck.to_check(right, param)
      quote do
        case unquote(left_check) do
          :ok -> :ok
          {:error, left_error} ->
            case unquote(right_check) do
              :ok -> :ok
              {:error, right_error} ->
                {:error, {TypeCheck.Builtin.Or, :both_failed, %{left: left_error, right: right_error}, unquote(param)}}
            end
        end
        # with {:error, left_error} <- unquote(left_check),
        #      {:error, right_error} <- unquote(right_check) do
        #   {:error, {TypeCheck.Builtin.Or, :both_failed, %{left: left_error, right: right_error}, unquote(param)}}
        # else
        #   :ok ->
        #     :ok
        # end
      end
    end
  end
end
