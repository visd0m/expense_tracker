defmodule ExpenseTracker.MixProject do
  use Mix.Project

  def project do
    [
      app: :expense_tracker,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:poison, "~> 3.1"},
      {:csv, "~> 2.3"},
      {:xlsxir, "~> 1.6"},
      {:google_api_sheets, "~> 0.7.0"},
      {:goth, "~> 1.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
