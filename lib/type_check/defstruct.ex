defmodule TypeCheck.Defstruct do
  @moduledoc """
  Implements the `defstruct!` macro.

  To use this macro:
  - Ensure you `use TypeCheck` in your module
  - Also `use TypeCheck.Defstruct`

  And now call `defstruct!/1` when you want to define a struct.
  """

  defmacro __using__(_opts) do
    # if Module.get_attribute(__CALLER__.module, TypeCheck.Options) do
    quote do
      unless Module.get_attribute(__MODULE__, TypeCheck.Options) do
        raise TypeCheck.CompileError, """
        You need to `use TypeCheck` before calling `use TypeCheck.Defstruct`.

        These are separate steps to:
        - Be very explicit where `@type!`, `@spec!` etc. come from.
        - Allow customization by passing options to `use TypeCheck`.
        """
      end

      import TypeCheck.Defstruct
    end
  end

  @doc """
  Defines a struct and a TypeCheck type at the same time.


  # Example:

      defmodule User do
        use TypeCheck
        use TypeCheck.Defstruct

        defstruct!(
          name: _ :: String.t(),
          age: :secret :: non_neg_integer() | :secret
        )
      end

  This is syntactic sugar for:

  defmodule User do
      use TypeCheck
      use TypeCheck.Defstruct

      @type! t() :: %User{
        name: String.t(),
        age: non_neg_integer() | :secret
      }
      @enforce_keys [:name]
      defstruct [:name, age: nil]
  end

  ## Optional and required keys

  A key is considered optional if it uses the syntax

      name: default_value :: type

  A key is considered required if it uses one of the following syntaxes:

      :name :: type

      name: _ :: type

  In this case, it will be added to the `@enforce_keys` list. (c.f. `Kernel.defstruct`).
  """
  defmacro defstruct!(fields_with_types) do
    full_info = extract_fields(fields_with_types)

    type_ast = type_ast(full_info, __CALLER__)
    enforced_keys = enforced_keys(full_info)
    struct_info = struct_info(full_info)

    res =
      quote generated: true do
        @enforce_keys unquote(enforced_keys)
        defstruct(unquote(struct_info))
        unquote(type_ast)
      end

    res
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.puts

    res
  end

  defp extract_fields(fields_with_types_ast) do
    Enum.map(fields_with_types_ast, &extract_field/1)
  end

  defp extract_field(field_ast) do
    case field_ast do
      # :name :: type
      {:"::", _, [field_name, field_type_ast]} when is_atom(field_name) ->
        {field_name, field_type_ast, :required}

      # name: _ :: type
      {field_name, {:"::", _, [{:_, _, _}, field_type_ast]}} when is_atom(field_name) ->
        {field_name, field_type_ast, :required}

      # name: default :: type
      {field_name, {:"::", _, [default_value, field_type_ast]}} when is_atom(field_name) ->
        {field_name, field_type_ast, {:default, default_value}}
    end
  end

  defp enforced_keys(full_info) do
    Enum.flat_map(full_info, fn
      {field_name, _, :required} ->
        [field_name]

      _ ->
        []
    end)
  end

  defp struct_info(full_info) do
    Enum.map(full_info, fn
      {field_name, _, :required} -> field_name
      {field_name, _, {:default, default_value}} -> {field_name, default_value}
    end)
  end

  defp type_ast(full_info, caller) do
    full_fields_ast =
      Enum.map(full_info, fn {field_name, field_ast, _} -> {field_name, field_ast} end)

    quote generated: true do
      TypeCheck.Macros.type!(t() :: %unquote(caller.module){unquote_splicing(full_fields_ast)})
    end
  end
end
