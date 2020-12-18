# defmodule TypeCheck.CompilationChecker do
#   def __on_definition__(_env, kind, name, args, guards, body) do
#     args_str =
#       args
#       |> Enum.map(&inspect/1)
#       |> Enum.join(", ")

#     IO.puts("#{kind} #{name}(#{args_str}) when #{inspect(guards)} do")
#     # IO.inspect(args)
#     # IO.puts("and guards")
#     # IO.inspect(guards)
#     # IO.puts()
#     IO.puts(Macro.to_string(body[:do]))
#     IO.puts("end")
#   end
# end
