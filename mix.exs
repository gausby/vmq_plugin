defmodule VmqPlugin.Mixfile do
  use Mix.Project

  def project do
    [app: :vmq_plugin,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:ex_doc, ">= 0.12.0", only: [:dev]},
     {:earmark, ">= 0.2.1", only: [:dev]}]
  end
end
