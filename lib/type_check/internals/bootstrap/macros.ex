defmodule TypeCheck.Internals.Bootstrap.Macros do
  @moduledoc false
  # Used inside modules that want to add checks
  # where this is not possible because of cyclic dependencies otherwise
  defmacro if_recompiling?(kwargs) do
    doblock = kwargs[:do] || quote do end
    elseblock = kwargs[:else] || quote do end

    case Code.ensure_loaded(__CALLER__.module) do
      {:module, _} -> doblock
      {:error, _} -> elseblock
    end
  end

  defmacro recompile(module, filename) do
    quote do
      prev = Code.get_compiler_option(:ignore_module_conflict)
      Code.put_compiler_option(:ignore_module_conflict, true)
      require unquote(module)
      Code.compile_file(unquote(filename))
      Code.put_compiler_option(:ignore_module_conflict, prev)
    end
  end
end
