defmodule Bench do
  def reset_rand(_), do: :rand.seed(:exrop, {1, 2, 3})

  def run(size) do
    IO.puts("============ #{size} elements ============\n")
    :rand.seed(:exrop, {1, 2, 3})
    data = Enum.shuffle(1..size)
    set = Enum.reduce(data, MapSet.new(), fn x, set -> MapSet.put(set, x) end)
    tree = Enum.reduce(data, AVLTree.new(), fn x, tree -> AVLTree.put(tree, x) end)
    gb_set = Enum.reduce(data, :gb_sets.new(), fn x, set -> :gb_sets.add_element(x, set) end)
    ets = :ets.new(:tree, [:ordered_set, :public])
    Enum.each(data, &:ets.insert(ets, {&1, &1}))

    wordsize = :erlang.system_info(:wordsize)

    IO.puts("Flat size (bytes):")
    IO.puts("MapSet:            #{(:erts_debug.flat_size(set) - size) * wordsize}")
    IO.puts("AVLTree:           #{(:erts_debug.flat_size(tree) - size) * wordsize}")
    IO.puts("gb_set:            #{(:erts_debug.flat_size(gb_set) - size) * wordsize}")
    IO.puts("ETS (ordered_Set): #{:ets.info(ets, :memory) * wordsize}")

    gen_element = fn _ -> :rand.uniform(size * 2) end

    IO.puts("\n============ SEARCH ============")

    Benchee.run(
      %{
        "MapSet SEARCH" => &MapSet.member?(set, &1),
        "AVLTree SEARCH" => &AVLTree.member?(tree, &1),
        "gb_set SEARCH" => &:gb_sets.is_member(&1, gb_set),
        "ETS (ordered set) SEARCH" => &:ets.lookup(ets, &1)
      },
      warmup: 2,
      before_scenario: &reset_rand/1,
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
        "MapSet INSERT" => &MapSet.put(set, &1),
        "AVLTree INSERT" => &AVLTree.put(tree, &1),
        "gb_set INSERT" => &:gb_sets.add_element(&1, gb_set),
        "ETS (ordered set) INSERT" => &:ets.insert(ets, {&1, &1})
      },
      warmup: 2,
      before_scenario: &reset_rand/1,
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
        "MapSet DELETE" => &MapSet.delete(set, &1),
        "AVLTree DELETE" => &AVLTree.delete(tree, &1),
        "gb_set DELETE" => &:gb_sets.delete_any(&1, gb_set),
        "ETS (ordered set) DELETE" => &:ets.delete(ets, &1)
      },
      warmup: 2,
      before_scenario: &reset_rand/1,
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
