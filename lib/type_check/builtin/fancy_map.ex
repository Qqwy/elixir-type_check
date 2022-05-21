# defmodule TypeCheck.Builtin.FancyMap do
#   @moduledoc """
#   Checks whether a value is a map, which can contain `optional()` and `required()` fields

#   as well as fixed fields (when literal values are used as keys).

#   This is an improvement over `TypeCheck.Builtin.FixedMap` and `TypeCheck.Builtin.Map`
#   in a sense that it tries to support both.

#   Work in progress.
#   """
#   defstruct [:fixed_keypairs, :required_keypairs, :optional_keypairs, :other_fields_allowed?]

#   defimpl TypeCheck.Protocols.ToCheck do
#     def to_check(s = %TypeCheck.Builtin.FancyMap{}, param) do
#     #   # TODO
#     #   res =
#     #     quote generated: true, location: :keep do
#     #     with {:ok, _, _} <- unquote(map_check(param, s)),
#     #          {:ok, _, _} <- unquote(build_fixed_keys_presence_ast(s, param))
#     #       do
#     #       {:ok, bindings, altered_param}
#     #     end
#     #       {:ok, [], unquote(param)}
#     #     end
#     #   res
#       quote do
#         {:ok, [], unquote(param)}
#       end
#     end
#   end


#   defimpl TypeCheck.Protocols.Inspect do
#     def inspect(s, _opts) do
#       # map = Enum.into(s.fixed_keypairs, %{})
#       inspect(s)
#       # fixed_elems =
#       #   s.fixed_keypairs
#       #   |> Elixir.Inspect.inspect(%Inspect.Opts{opts | inspect_fun: &TypeCheck.Protocols.Inspect.inspect/2})
#       #   |> Inspect.Algebra.color(:builtin_type, opts)

#       # required_elems =
#       #   s.fixed_keypairs
#       #   |> Elixir.Inspect.inspect(%Inspect.Opts{opts | inspect_fun: &TypeCheck.Protocols.Inspect.inspect/2})
#       #   |> Inspect.Algebra.color(:builtin_type, opts)
#     end
#   end
# end
