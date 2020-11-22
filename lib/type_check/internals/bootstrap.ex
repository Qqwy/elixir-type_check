defmodule TypeCheck.Internals.Bootstrap do
  require __MODULE__.Macros
  # Waiting for TypeCheck.Builtin.* to be compiled
  # ensures deterministic compilation
  # (otherwise compilation might deadlock).
  # A bit of a hack, suggestions are welcome.
  case Code.ensure_compiled(TypeCheck.Builtin.Any) do
    {:error, problem} -> IO.puts(problem)
    {:module, _} ->

      __MODULE__.Macros.recompile(TypeCheck.Options, "lib/type_check/options.ex")
      __MODULE__.Macros.recompile(TypeCheck.Builtin, "lib/type_check/builtin.ex")

  end
end
