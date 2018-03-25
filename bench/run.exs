defmodule Run do
  def get_data(number) do
    get_data([], 1..number |> Enum.map(fn x -> {x, x} end) |> Enum.into(%{}))
  end

  def get_data(result, map) do
    if Map.size(map) == 0 do
      result
    else
      s = Map.size(map)
      n = :rand.uniform(s)
      get_data([map[n] | result], map |> Map.put(n, map[s]) |> Map.delete(s))
    end
  end
end

:rand.seed(:exrop, {1, 2, 3})

data = Run.get_data(100_000)

Benchee.run(
  %{
    "MapSet" => fn ->
      Enum.reduce(data, MapSet.new(), fn x, set -> MapSet.put(set, x) end)
    end,
    "AVLTree" => fn ->
      Enum.reduce(data, AVLTree.new(), fn x, tree -> AVLTree.put(tree, x) end)
    end
  },
  time: 10
)
