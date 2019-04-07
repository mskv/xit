defmodule Xit.MixProject do
  use Mix.Project

  def project do
    [
      app: :xit,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5"}
    ]
  end
end
