# AVLTree

Pure Elixir [AVL tree](https://en.wikipedia.org/wiki/AVL_tree) implementation.

This data structure is very similar to `MapSet`, but unlike the latter,
elements in the `AVLTree` are always sorted in ascending or descending order.

To sort items, `AVLTree` uses a comparison function that looks like:

`less(a, b) :: boolean`

This function returns `true` if element `a` must be placed strictly before element `b`, otherwise it returns false.

`AVLTree` can store duplicate elements.
It is important to understand that duplicate elements are not necessarily the same.

Values `a` and `b` are considered equal if they satisfy the following condition:

`less(a, b) == false and less(b, a) == false`, where `less(x, y)` is comparison function

For example, if the comparison function is `fn {a, _}, {b, _} -> a < b end`,
then the elements `{1, 10}` and `{1, 20}` are considered equal, although actually they aren't.

By default, comparison function is `Kernel.</2`.

## Features

- custom comparison function;
- support for duplicate elements;
- `Collectable`, `Enumerable`, `Inspect` protocols;
- drawing the tree in the console :)

## Basic Usage

By default, inserted elements are sorted in ascending order:

```elixir
iex> tree = AVLTree.new()
#AVLTree<[]>
iex> tree = AVLTree.put(tree, 5)
iex> tree = AVLTree.put(tree, 2)
iex> tree = [1, 3, 6, 4] |> Enum.into(tree)
iex> tree
#AVLTree<[1, 2, 3, 4, 5, 6]>
```

You can specify ordering when creating a tree:

```elixir
iex> tree1 = AVLTree.new(:asc)
iex> tree2 = AVLTree.new(:desc)
iex> [4, 2, 1, 3] |> Enum.into(tree1)
#AVLTree<[1, 2, 3, 4]>
iex> [4, 2, 1, 3] |> Enum.into(tree2)
#AVLTree<[4, 3, 2, 1]>
```

Also you can use a custom comparison function.

Example of a tree with tuples as elements, ordered by the first field

```elixir
iex> tree = AVLTree.new(fn {a, _}, {b, _} -> a < b end)
iex> [{2, "A"}, {3, "B"}, {1, "C"}] |> Enum.into(tree)
#AVLTree<[{1, "C"}, {2, "A"}, {3, "B"}]>
```

Checks if the tree contains a value

```elixir
iex> tree = [5, 2, 1, 3] |> Enum.into(AVLTree.new())
iex> AVLTree.member?(tree, 2)
true
```

`AVLTree` fully supports `Enumerable` protocol

```elixir
iex> tree = [4, 2, 1, 3] |> Enum.into(AVLTree.new())
iex> Enum.to_list(tree)
[1, 2, 3, 4]
iex> Enum.sum(tree)
10
```

## Sorted list of dates

Let's create an ascending list of `DateTime` values.

```elixir
iex> tree = AVLTree.new(fn a, b -> DateTime.compare(a, b) == :lt end)
iex> [
...>   ~U[2020-02-03 01:01:01Z],
...>   ~U[2020-01-01 01:01:01Z],
...>   ~U[2019-10-10 02:11:01Z],
...>   ~U[2020-01-01 01:01:02Z]
...> ] |> Enum.into(tree)
#AVLTree<[~U[2019-10-10 02:11:01Z], ~U[2020-01-01 01:01:01Z], ~U[2020-01-01 01:01:02Z], ~U[2020-02-03 01:01:01Z]]>
```

## AVLTree as a map.

If you use a key-value pairs as elements, `AVLTree` can work as a map:

Create a tree

```elixir
tree = AVLTree.new(fn {a, _}, {b, _} -> a < b end)
```

Insert key-value pairs:

```elixir
tree =
    tree
    |> AVLTree.put({:a, "first value"})
    |> AVLTree.put({:c, "third value"})
    |> AVLTree.put({:b, "second value"})
```

or

```elixir
    tree =
      [a: "first value", c: "third value", b: "second value"]
      |> Enum.into(tree)
```

Retrieve element by key. We can use anything as a value since comparison function cares only about keys.

```elixir
AVLTree.get(tree, {:b, nil}) # {:b, "second value"}
```

Delete element:

```elixir
AVLTree.delete(tree, {:b, nil}) # #AVLTree<[a: "first value", c: "third value"]>
```

Benefits? Elements are always ordered by keys. Custom comparison function.

## Performance

All inserts, removes and searches in general has complexity of `Ο(lg(n))`.

This implementation is about 4-5 times slower than `MapSet`.

To run benchmark use:

```shell
mix run bench/run.exs
```
