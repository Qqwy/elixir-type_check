defmodule TypeCheck.Type do
  @moduledoc """
  TODO
  """
  import TypeCheck.Internals.Bootstrap.Macros
  if_recompiling? do
    use TypeCheck
  end

  @typedoc """
  Something is a TypeCheck.Type if it implements the TypeCheck.Protocols.ToCheck protocol.

  It is also expected to implement the TypeCheck.Protocols.Inspect protocol (although that has an `Any` fallback).

  In practice, this type means 'any of the' structs in the `TypeCheck.Builtin.*` modules.
  """
  if_recompiling? do
    @type! t() :: (x :: any() when TypeCheck.Type.type?(x))
  else
    @type t() :: any()
  end

  # To allow types to refer to this type
  # @doc false
  # def t do
  #   import TypeCheck.Builtin
  #   any()
  # end

  @typedoc """
  Indicates that we expect a 'type AST' that will be expanded
  to a proper type. This means that it might contain essentially the full syntax that Elixir Typespecs
  allow, which will be rewritten to calls to the functions in `TypeCheck.Builtin`.

  See `TypeCheck.Builtin` for the precise syntax you are allowed to use.
  """
  @type expandable_type() :: any()

  @doc """
  Constructs a concrete type from the given `type_ast`.

  This means that you can pass type-syntax to this macro,
  which will be transformed into explicit calls to the functions in `TypeCheck.Builtin`.

      iex> res = TypeCheck.Type.build(:ok | :error)
      iex> res
      #TypeCheck.Type< :ok | :error >
      iex> # This is the same as:
      iex> import TypeCheck.Builtin, only: [one_of: 2, literal: 1]
      iex> explicit = one_of(literal(:ok), literal(:error))
      iex> res == explicit
      true

      iex> res = TypeCheck.Type.build({a :: number(), b :: number()} when a <= b)
      iex> res
      #TypeCheck.Type< ({a :: number(), b :: number()} when a <= b) >
      iex> # This is the same as:
      iex> import TypeCheck.Builtin, only: [fixed_tuple: 1, number: 0, guarded_by: 2, named_type: 2]
      iex> explicit = guarded_by(fixed_tuple([named_type(:a, number()), named_type(:b, number())]), quote do a <= b end)
      iex> explicit
      #TypeCheck.Type< ({a :: number(), b :: number()} when a <= b) >

  Of course, you can refer to your own local and remote types as well.
  """
  defmacro build(type_ast, options \\ TypeCheck.Options.new()) do
    options = TypeCheck.Options.new(options)

    type_ast
    |> build_unescaped(__CALLER__, options)
    |> Macro.escape()
  end

  @doc false
  # Building block of macros that take an unexpanded type-AST as input.
  #
  # Transforms `type_ast` (which is expected to be a quoted Elixir AST) into a type value.
  # The result is _not_ escaped
  # assuming that you'd want to do further compile-time work with the type.
  def build_unescaped(type_ast, caller, typecheck_options, add_typecheck_module \\ false) do
    type_ast = TypeCheck.Internals.PreExpander.rewrite(type_ast, caller, typecheck_options)

    code =
      if add_typecheck_module do
        compile_time_imports_module_name =
          Module.concat(TypeCheck.Internals.UserTypes, caller.module)

        quote do
          import unquote(compile_time_imports_module_name)
          unquote(type_ast)
        end
      else
        type_ast
      end

    {type, []} = Code.eval_quoted(code, [], caller)
    type
  end

  defmacro to_typespec(type) do
    TypeCheck.Internals.ToTypespec.rewrite(type, __CALLER__)
  end

  def type?(possibly_a_type) do
    TypeCheck.Protocols.ToCheck.impl_for(possibly_a_type) != nil
  end

  @doc false
  def ensure_type!(possibly_a_type) do
    case TypeCheck.Protocols.ToCheck.impl_for(possibly_a_type) do
      nil ->
        raise """
        Invalid value passed to a function expecting a type!
        `#{inspect(possibly_a_type)}` is not a valid TypeCheck type.
        You probably tried to use a TypeCheck type as a function directly.

        Instead, either implement named types using the `type`, `typep`, `opaque` macros,
        or use TypeCheck.Type.build/1 to construct a one-off type.

        Both of these will perform the necessary conversions to turn 'normal' datatypes to types.
        """

      _other ->
        :ok
    end
  end
end
