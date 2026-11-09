defmodule Support.MixProject do
  use Mix.Project

  def project do
    [app: :support, version: "0.1.0", elixir: "~> 1.15", deps: [{:req, "~> 0.7.5"}]]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
