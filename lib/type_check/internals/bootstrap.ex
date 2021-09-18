require TypeCheck.Internals.Bootstrap.Macros
# Waiting for TypeCheck.Builtin.* to be compiled
# ensures deterministic compilation
# (otherwise compilation might deadlock).
# A bit of a hack, suggestions are welcome.
case Code.ensure_compiled(TypeCheck.Builtin.Any) do
  {:error, problem} -> IO.puts(problem)
  {:module, _} ->

    TypeCheck.Internals.Bootstrap.Macros.recompile(TypeCheck.Type, "lib/type_check/type.ex")
    TypeCheck.Internals.Bootstrap.Macros.recompile(TypeCheck.Options, "lib/type_check/options.ex")
    TypeCheck.Internals.Bootstrap.Macros.recompile(TypeCheck.Builtin, "lib/type_check/builtin.ex")
end
