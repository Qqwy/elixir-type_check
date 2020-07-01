defmodule TypeCheck do
  require TypeCheck.Type

  @moduledoc """
  Fast and flexible runtime type-checking.

  The main way to use TypeCheck is by adding `use TypeCheck` in your modules.
  This will allow you to use the macros of `TypeCheck.Macros` in your module.
  It will also bring all functions in `TypeCheck.Builtin` in scope,
  which is usually what you want.


  Using these, you're able to add function-specifications to your functions
  which will wrap them with runtime type-checks.
  You'll also be able to create your own type-specifications that can be used
  in other type- and function-specifications in the same or other modules later on.

  ## Manual type-checking

  If you want to check values against a type _outside_ of the checks the `spec` macro
  wraps a function with,
  you can use the `conforms/2`/`conforms?/2`/`conforms!/2` macros in this module directly in your code.

  These are evaluated _at compile time_ which means the resulting checks will be optimized by the compiler.
  Unfortunately it also means that the types passed to them have to be known at compile time.

  If you have a type that is constructed dynamically at runtime, you can resort to
  `dynamic_conforms` and variants.
  Because these have to evaluate the type-checking code at runtime,
  these checks be optimized by the compiler.

  ## I get naming conflicts with TypeCheck.Builtin

  If you want to define a type with the same name as one in TypeCheck.Builtin,
  you should hide those particular functions from TypeCheck.Builtin by adding
  an `import TypeCheck.Builtin, except: [...]`-statement
  below the `use TypeCheck` manually.
  """

  defmacro __using__(_options) do
    quote do
      use TypeCheck.Macros
      import TypeCheck.Builtin
    end
  end

  @doc """
  Makes sure `value` typechecks the type description `type`.

  If it typechecks, we return `{:ok, value}`
  Otherwise, we return `{:error, %TypeCheck.TypeError{}}` which contains information
  about why the value failed the check.

  `conforms` is a macro and expands the type check at compile-time,
  allowing it to be optimized by the compiler.

  C.f. `TypeCheck.Type.build/1` for more information on what type-expressions
  are allowed as `type` parameter.
  """
  @type value :: any()
  @spec conforms(value, TypeCheck.Type.expandable_type()) :: {:ok, value} | {:error, TypeCheck.TypeError.t()}
  defmacro conforms(value, type) do
    type = TypeCheck.Type.build_unescaped(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      case unquote(check) do
        {:ok, bindings} -> {:ok, unquote(value)}
        {:error, problem} -> {:error, TypeCheck.TypeError.exception(problem)}
      end
    end
  end

  @doc """
  Similar to `conforms`, but returns `true` if the value typechecked and `false` if it did not.

  The same features and restrictions apply to this function as to `conforms/2`.
  """
  @spec conforms?(value, TypeCheck.Type.expandable_type()) :: boolean()
  defmacro conforms?(value, type) do
    type = TypeCheck.Type.build_unescaped(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      match?({:ok, _}, unquote(check))
    end
  end

  @doc """
  Similar to `conforms`, but returns `value` if the value typechecked and raises TypeCheck.TypeError if it did not.

  The same features and restrictions apply to this function as to `conforms/2`.
  """
  @spec conforms!(value, TypeCheck.Type.expandable_type()) :: value | no_return()
  defmacro conforms!(value, type) do
    type = TypeCheck.Type.build_unescaped(type, __CALLER__)
    check = TypeCheck.Protocols.ToCheck.to_check(type, value)
    quote do
      case unquote(check) do
        {:ok, _bindings} -> unquote(value)
        {:error, other} -> raise TypeCheck.TypeError, other
      end
    end
  end

  @doc """

  Makes sure `value` typechecks the type `type`. Evaluated _at runtime_.

  Because `dynamic_conforms` is evaluated at runtime:

  1. The typecheck cannot be optimized by the compiler, which makes it slower.

  2. You must pass an already-expanded type as `type`.
     This can be done by using one of your custom types directly (e.g. `YourModule.typename()`),
     or by calling `TypeCheck.Type.build`.

  Use `dynamic_conforms` only when you cannot use the normal `conforms`,
  for instance when you're only able to construct the type to check against at runtime.
  """
  @spec dynamic_conforms(value, TypeCheck.Type.t) :: {:ok, value} | {:error, TypeCheck.TypeError.t}
  def dynamic_conforms(value, type) do
    check_code = TypeCheck.Protocols.ToCheck.to_check(type, Macro.var(:value, nil))
    case Code.eval_quoted(check_code, [value: value]) do
      {{:ok, _}, _} -> {:ok, value}
      {{:error, problem}, _} -> {:error, TypeCheck.TypeError.exception(problem)}
    end
  end

  @doc """
  Similar to `dynamic_conforms`, but returns `true` if the value typechecked and `false` if it did not.

  The same features and restrictions apply to this function as to `dynamic_conforms/2`.
  """
  @spec dynamic_conforms?(value, TypeCheck.Type.t) :: boolean
  def dynamic_conforms?(value, type) do
    case dynamic_conforms(value, type) do
      {:ok, _value} -> true
      _other -> false
    end
  end

  @doc """
  Similar to `dynamic_conforms`, but returns `value` if the value typechecked and raises TypeCheck.TypeError if it did not.

  The same features and restrictions apply to this function as to `dynamic_conforms/2`.
  """
  @spec dynamic_conforms!(value, TypeCheck.Type.t) :: value | no_return()
  def dynamic_conforms!(value, type) do
    case dynamic_conforms(value, type) do
      {:ok, value} -> value
      {:error, exception} -> raise exception
    end
  end
end
