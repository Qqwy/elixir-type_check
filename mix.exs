defmodule TypeCheck.MixProject do
  use Mix.Project

  def project do
    [
      app: :type_check,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "TypeCheck",
      source_url: "https://github.com/Qqwy/elixir-type_check",
      homepage_url: "https://github.com/Qqwy/elixir-type_check",
      docs: [
        main: "TypeCheck"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :stream_data]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:stream_data, "~> 0.5.0", optional: true},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end
end
