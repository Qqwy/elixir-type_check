defmodule TypeCheck.Builtin.CompoundFixedMap do
  @moduledoc """
  Special type for map-typespecs that contain a combination of fixed keys as well as an `optional(...)` or `required(...)` part.

  Its checks compile down to a combination of `TypeCheck.Builtin.FixedMap` and `TypeCheck.Builtin.Map`
  for the fixed resp. non-fixed parts.
  """

  defstruct [:fixed, :flexible]

  use TypeCheck
  @type! t :: %__MODULE__{fixed: TypeCheck.Builtin.FixedMap.t(), flexible: TypeCheck.Builtin.Map.t()}

  @type! problem_tuple :: TypeCheck.Builtin.FixedMap.problem_tuple() | TypeCheck.Builtin.Map.problem_tuple()

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s = %TypeCheck.Builtin.CompoundFixedMap{}, param) do
      # NOTE: We cannot use Keyword here since the keys are not atoms but arbitrary values
      fixed_keys = s.fixed.keypairs |> Enum.map(fn {key, _val} -> key end)
      fixed_part_var = Macro.var(:fixed_Part, __MODULE__)
      flexible_part_var = Macro.var(:fixed_Part, __MODULE__)

      res =
        quote generated: :true, location: :keep do
        compound_map = unquote(param)
          with {:ok, _, _} <- map_check(compound_map, s),
            {unquote(fixed_part_var), unquote(flexible_part_var)} = Map.split(compound_map, unquote(fixed_keys)),
               {:ok, bindings1, fixed_part} <- unquote(TypeCheck.Protocols.ToCheck.to_check(s.fixed, fixed_part_var)),
               {:ok, bindings2, flexible_part} <- unquote(TypeCheck.Protocols.ToCheck.to_check(s.flexible, flexible_part_var))
            do
            {:ok, bindings1 ++ bindings2, Map.merge(fixed_part, flexible_part)}
          end
        end

      res
    end

    defp map_check(param, s) do
      quote generated: true, location: :keep do
        case unquote(param) do
          val when is_map(val) ->
            {:ok, [], val}
          other ->
            {:error, {unquote(Macro.escape(s)), :not_a_map, %{}, other}}
        end
      end
    end
  end


  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      fixed_keypairs_str = Inspect.Algebra.container_doc("%{", s.fixed.keypairs, "", opts, &to_map_kv(&1, &2), separator: ",", break: :strict)

      flexible_key_str = TypeCheck.Protocols.Inspect.inspect(s.flexible.key_type, opts)
      flexible_val_str = TypeCheck.Protocols.Inspect.inspect(s.flexible.value_type, opts)
      flexible_str = Inspect.Algebra.concat(["optional(", flexible_key_str, ") => ", flexible_val_str])

      Inspect.Algebra.concat([fixed_keypairs_str, ", ", flexible_str, "}"])
    end

    defp to_map_kv({key, value_type}, opts) do
      import Inspect.Algebra, only: [color: 3, concat: 2, to_doc: 2]
      value_doc = TypeCheck.Protocols.Inspect.inspect(value_type, opts)

      if non_module_atom?(key) do
        key = color(Code.Identifier.inspect_as_key(key), :atom, opts)
        concat(key, concat(" ", value_doc))
      else
        sep = color(" =>", :map, opts)
        concat(concat(to_doc(key, opts), sep), value_doc)
      end
    end

    defp non_module_atom?(val) do
      is_atom(val) and !match?('Elixir.' ++ _, Atom.to_charlist(val))
    end
  end
end
