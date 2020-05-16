defmodule Bench do
  def run(size) do
    IO.puts("============ #{size} elements ============\n")
    :rand.seed(:exrop, {1, 2, 3})
    data = Enum.shuffle(1..size)
    set = Enum.reduce(data, MapSet.new(), fn x, set -> MapSet.put(set, x) end)
    tree = Enum.reduce(data, AVLTree.new(), fn x, tree -> AVLTree.put(tree, x) end)

    IO.puts("Flat size (bytes):")
    IO.puts("MapSet:  #{:erts_debug.flat_size(set) - size}")
    IO.puts("AVLTree: #{:erts_debug.flat_size(tree) - size}")

    gen_element = fn _ -> :rand.uniform(size * 2) end

    IO.puts("\n============ SEARCH ============")

    Benchee.run(
      %{
        "MapSet SEARCH" => fn x -> MapSet.member?(set, x) end,
        "AVLTree SEARCH" => fn x -> AVLTree.member?(tree, x) end
      },
      before_each: gen_element,
      time: 5,
      print: %{
        benchmarking: false,
        configuration: false
      }
    )

    IO.puts("\n============ INSERT ============")

    Benchee.run(
      %{
        "MapSet INSERT" => fn x -> MapSet.put(set, x) end,
        "AVLTree INSERT" => fn x -> AVLTree.put(tree, x) end
      },
      before_each: gen_element,
      time: 5,
      print: %{
        benchmarking: false,
        configuration: false
      }
    )

    IO.puts("\n============ DELETE ============")

    Benchee.run(
      %{
        "MapSet DELETE" => fn x -> MapSet.delete(set, x) end,
        "AVLTree DELETE" => fn x -> AVLTree.delete(tree, x) end
      },
      before_each: gen_element,
      time: 5,
      print: %{
        benchmarking: false,
        configuration: false
      }
    )
  end
end

case System.argv() do
  [a | _] ->
    case Integer.parse(a) do
      {n, ""} -> Bench.run(n)
      _ -> IO.puts("integer expected")
    end

  _ ->
    Bench.run(100_000)
end
