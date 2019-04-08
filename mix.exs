defmodule Xit.MixProject do
  use Mix.Project

  def project do
    [
      app: :xit,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps()
    ]
  end

  defp escript do
    [
      main_module: Xit.Cli
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5"}
    ]
  end
end
