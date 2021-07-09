defmodule NaturalTime.MixProject do
  use Mix.Project

  def project do
    [
      app: :natural_time,
      version: "0.1.0",
      elixir: "~> 1.8",
      description: "A simple parser for datetime in natural language",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:timex, "~> 3.5"},
      {:nimble_parsec, "~> 1.1"},
      # neeeded for publishing to hex
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "natural_time",
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["MIT"],
      links: %{
        "github" => "https://github.com/shouya/natural-time"
      }
    ]
  end
end
