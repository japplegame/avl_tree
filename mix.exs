defmodule AvlTree.MixProject do
  use Mix.Project

  def project do
    [
      app: :avl_tree,
      version: "1.0.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      name: "AVLTree",
      description: "Pure Elixir AVL tree implementation",
      deps: deps(),
      docs: [extras: ["README.md"]],
      package: [
        maintainers: ["Jack Applegame"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/japplegame/avl_tree"},
        files: ["lib", "test", "bench", "mix.exs", "README.md", "LICENSE"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.22", only: :dev}
    ]
  end
end
