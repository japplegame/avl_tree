defmodule Bench do
  @elements 100_000
  @time 10

  def get_data(number) do
    get_data([], 1..number |> Enum.map(fn x -> {x, x} end) |> Enum.into(%{}))
  end

  def get_data(result, map) do
    if map_size(map) == 0 do
      result
    else
      s = map_size(map)
      n = :rand.uniform(s)
      get_data([map[n] | result], map |> Map.put(n, map[s]) |> Map.delete(s))
    end
  end

  def run() do
    :rand.seed(:exrop, {1, 2, 3})
    data1 = get_data(@elements)
    data2 = get_data(@elements)
    set = Enum.reduce(data1, MapSet.new(), fn x, set -> MapSet.put(set, x) end)
    tree = Enum.reduce(data1, AVLTree.new(), fn x, tree -> AVLTree.put(tree, x) end)

    IO.puts("Memory consumtion:\n")
    IO.puts("  MapSet:  #{:erts_debug.flat_size(set) - @elements}")
    IO.puts("  AVLTree: #{:erts_debug.flat_size(tree) - @elements}\n")

    Benchee.run(
      %{
        "MapSet INSERT" => fn ->
          Enum.reduce(data1, MapSet.new(), fn x, set -> MapSet.put(set, x) end)
        end,
        "AVLTree INSERT" => fn ->
          Enum.reduce(data1, AVLTree.new(), fn x, tree -> AVLTree.put(tree, x) end)
        end
      },
      time: @time
    )

    IO.puts("\n")

    Benchee.run(
      %{
        "MapSet SEARCH" => fn ->
          Enum.each(data2, fn x -> MapSet.member?(set, x) end)
        end,
        "AVLTree SEARCH" => fn ->
          Enum.each(data2, fn x -> AVLTree.member?(tree, x) end)
        end
      },
      time: 10
    )
  end
end

Bench.run()
