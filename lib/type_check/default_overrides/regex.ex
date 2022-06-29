defmodule TypeCheck.DefaultOverrides.Regex do
  use TypeCheck
  import TypeCheck.Type.StreamData
  @type! t() :: wrap_with_gen(
      %Elixir.Regex{
        opts: binary(),
        re_pattern: term(),
        re_version: term(),
        source: binary()
      },
      &TypeCheck.DefaultOverrides.Regex.regex_gen/0
    )

  if Code.ensure_loaded?(StreamData) do
    def regex_gen do
      :ascii
      |> StreamData.string(min_length: 1)
      |> StreamData.map(&Regex.compile/1)
      # filtering here is SLOW, but a faster solution
      # would be significntly more complex
      |> StreamData.filter(fn
        {:ok, _} -> true
        {:error, _} -> false
      end)
      |> StreamData.map(fn {:ok, re} -> re end)
    end
  else
    def regex_gen do
      raise TypeCheck.CompileError, "This function requires the optional dependency StreamData."
    end
  end
end
