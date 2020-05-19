defmodule AVLTree do
  @moduledoc """

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
  """
  alias __MODULE__.Node

  defstruct root: nil, size: 0, less: &Kernel.</2

  @doc """
  Creates a new tree with default ascending order.

  ```
  iex> [3, 1, 4, 2] |> Enum.into(AVLTree.new())
  #AVLTree<[1, 2, 3, 4]>
  ```
  """
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @doc """
  Creates a new tree with the given `ordering` or comparison function.

  ```
  iex> [3, 1, 4, 2] |> Enum.into(AVLTree.new(:asc))
  #AVLTree<[1, 2, 3, 4]>
  iex> [3, 1, 4, 2] |> Enum.into(AVLTree.new(:desc))
  #AVLTree<[4, 3, 2, 1]>
  iex> [3, 1, 4, 2] |> Enum.into(AVLTree.new(fn a, b -> a > b end))
  #AVLTree<[4, 3, 2, 1]>
  ```
  """
  @spec new(:asc | :desc | less()) :: t()
  def new(ordering) when is_function(ordering) do
    %__MODULE__{less: ordering}
  end

  def new(:asc) do
    %__MODULE__{less: &Kernel.</2}
  end

  def new(:desc) do
    %__MODULE__{less: &Kernel.>/2}
  end

  @doc """
  Returns height of the tree.

  ```
  iex> tree = [5, 9, 3, 8, 1, 6, 7] |> Enum.into(AVLTree.new())
  #AVLTree<[1, 3, 5, 6, 7, 8, 9]>
  iex> AVLTree.height(tree)
  4
  ```
  """
  @spec height(t()) :: integer()
  def height(%__MODULE__{root: root}) do
    Node.height(root)
  end

  @doc """
  Returns the number of elements in the tree

  ```
  iex> tree = [5, 9, 3, 8, 1, 6, 7] |> Enum.into(AVLTree.new())
  #AVLTree<[1, 3, 5, 6, 7, 8, 9]>
  iex> AVLTree.size(tree)
  7
  ```
  """
  @spec size(t()) :: integer()
  def size(%__MODULE__{size: size}) do
    size
  end

  @doc """
  Retrieves an element equal to `value`.

  If the tree contains more than one element equal to `value`, retrieves one of them. It is undefined which one.

  Returns `defailt` if nothing is found.

  ```
  iex> tree = AVLTree.new(fn {a, _}, {b, _} -> a < b end)
  #AVLTree<[]>
  iex> tree = [a: "A", c: "C", d: "D", b: "B"] |> Enum.into(tree)
  #AVLTree<[a: "A", b: "B", c: "C", d: "D"]>
  iex> AVLTree.get(tree, {:c, nil}, :error)
  {:c, "C"}
  iex> AVLTree.get(tree, {:e, nil}, :error)
  :error
  ```
  """
  @spec get(t(), value(), term()) :: value() | term()
  def get(%__MODULE__{root: root, less: less}, value, default \\ nil) do
    Node.get(root, value, default, less)
  end

  @doc """
  Retrieves the first value in the tree.

  Returns `default` if the tree is empty.

  ```
  iex> tree = [3, 2, 4, 6] |> Enum.into(AVLTree.new())
  #AVLTree<[2, 3, 4, 6]>
  iex> AVLTree.get_first(tree)
  2
  ```
  """
  @spec get_first(t(), term()) :: value() | term()
  def get_first(%__MODULE__{root: root}, default \\ nil) do
    Node.get_first(root, default)
  end

  @doc """
  Retrieves the last value in the tree.

  Returns `default` if the tree is empty.

  ```
  iex> tree = [3, 2, 4, 6] |> Enum.into(AVLTree.new())
  #AVLTree<[2, 3, 4, 6]>
  iex> AVLTree.get_last(tree)
  6
  ```
  """
  @spec get_last(t(), term()) :: value() | term()
  def get_last(%__MODULE__{root: root}, default \\ nil) do
    Node.get_last(root, default)
  end

  @doc """
  Retrieves an element equal to `value`.

  If the tree contains more than one element equal to `value`, retrieves the first of them

  Returns `default` if nothing is found.

  ```
  iex> tree = [b: 21, a: 1, b: 22, c: 3, b: 23] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<[a: 1, b: 21, b: 22, b: 23, c: 3]>
  iex> AVLTree.get_lower(tree, {:b, nil})
  {:b, 21}
  ```
  """
  @spec get_lower(t(), value(), term()) :: value() | term()
  def get_lower(%__MODULE__{root: root, less: less}, value, default \\ nil) do
    Node.get_lower(root, value, default, less)
  end

  @doc """
  Retrieves an element equal to `value`.

  If the tree contains more than one element equal to `value`, retrieves the last of them

  Returns `default` if nothing is found.

  ```
  iex> tree = [b: 21, a: 1, b: 22, c: 3, b: 23] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<[a: 1, b: 21, b: 22, b: 23, c: 3]>
  iex> AVLTree.get_upper(tree, {:b, nil})
  {:b, 23}
  ```
  """
  @spec get_upper(t(), value(), term()) :: value() | term()
  def get_upper(%__MODULE__{root: root, less: less}, value, default \\ nil),
    do: Node.get_upper(root, value, default, less)

  @doc """
  Checks if the tree contains an element equal to `value`.

  ```
  iex> tree = [3, 2, 4, 6] |> Enum.into(AVLTree.new())
  #AVLTree<[2, 3, 4, 6]>
  iex> AVLTree.member?(tree, 4)
  true
  iex> AVLTree.member?(tree, 1)
  false
  ```
  """
  @spec member?(t(), term()) :: boolean()
  def member?(%__MODULE__{root: root, less: less}, value), do: Node.member?(root, value, less)

  @doc """
  Puts the given `value` in the tree.

  If the tree already contains elements equal to `value`, replaces one of them. It is undefined which one.

  ```
  iex> tree = [b: 2, a: 1, c: 3] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<[a: 1, b: 2, c: 3]>
  iex> AVLTree.put(tree, {:d, 4})
  #AVLTree<[a: 1, b: 2, c: 3, d: 4]>
  iex> AVLTree.put(tree, {:a, 11})
  #AVLTree<[a: 11, b: 2, c: 3]>
  ```
  """
  @spec put(t(), value()) :: t()
  def put(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    case Node.put(root, value, less) do
      {:update, root} -> %{avl_tree | root: root}
      root -> %{avl_tree | root: root, size: size + 1}
    end
  end

  @doc """
  Puts the given `value` in the tree.

  If the tree already contains elements equal to `value`, inserts `value` before them.

  ```
  iex> tree = [b: 21, a: 11, d: 41, c: 31] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<[a: 11, b: 21, c: 31, d: 41]>
  iex> tree = AVLTree.put_lower(tree, {:a, 12})
  #AVLTree<[a: 12, a: 11, b: 21, c: 31, d: 41]>
  iex> tree = AVLTree.put_lower(tree, {:b, 22})
  #AVLTree<[a: 12, a: 11, b: 22, b: 21, c: 31, d: 41]>
  iex> AVLTree.put_lower(tree, {:d, 42})
  #AVLTree<[a: 12, a: 11, b: 22, b: 21, c: 31, d: 42, d: 41]>
  ```
  """
  @spec put_lower(t(), value()) :: t()
  def put_lower(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    %{avl_tree | root: Node.put_lower(root, value, less), size: size + 1}
  end

  @doc """
  Puts the given `value` in the tree.

  If the tree already contains elements equal to `value`, inserts `value` after them.
  ```
  iex> tree = [b: 21, a: 11, d: 41, c: 31] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<[a: 11, b: 21, c: 31, d: 41]>
  iex> tree = AVLTree.put_upper(tree, {:a, 12})
  #AVLTree<[a: 11, a: 12, b: 21, c: 31, d: 41]>
  iex> tree = AVLTree.put_upper(tree, {:b, 22})
  #AVLTree<[a: 11, a: 12, b: 21, b: 22, c: 31, d: 41]>
  iex> AVLTree.put_upper(tree, {:d, 42})
  #AVLTree<[a: 11, a: 12, b: 21, b: 22, c: 31, d: 41, d: 42]>
  ```

  `Enum.into/2` uses `put_upper/2`:

  ```
  iex> [a: 11, c: 31, a: 12, b: 21, a: 13] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end)) |> Enum.to_list()
  [a: 11, a: 12, a: 13, b: 21, c: 31]
  ```
  """
  @spec put_upper(t(), value()) :: t()
  def put_upper(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    %{avl_tree | root: Node.put_upper(root, value, less), size: size + 1}
  end

  @doc """
  Deletes an element equal to the given `value`.

  If the tree contains more than one element equal to `value`, deletes one of them. It is undefined which one.

  If no element is found, returns the tree unchanged.

  ```
  iex> tree = [3, 2, 1, 4] |> Enum.into(AVLTree.new())
  #AVLTree<[1, 2, 3, 4]>
  iex> AVLTree.delete(tree, 3)
  #AVLTree<[1, 2, 4]>
  iex> AVLTree.delete(tree, 5)
  #AVLTree<[1, 2, 3, 4]>
  ```
  """
  @spec delete(t(), value()) :: t()
  def delete(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    case Node.delete(root, value, less) do
      {true, a} -> %{avl_tree | root: a, size: size - 1}
      {false, _} -> avl_tree
    end
  end

  @doc """
  Deletes an element equal to the given `value`.

  If the tree contains more than one element equal to `value`, deletes the first of them.

  If no element is found, returns the tree unchanged.

  ```
  iex> tree = [b: 21, a: 1, b: 22, c: 3, b: 23] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<[a: 1, b: 21, b: 22, b: 23, c: 3]>
  iex> AVLTree.delete_lower(tree, {:b, nil})
  #AVLTree<[a: 1, b: 22, b: 23, c: 3]>
  ```
  """
  @spec delete_lower(t(), value()) :: {:ok, t()} | :error
  def delete_lower(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    case Node.delete_lower(root, value, less) do
      {true, a} -> %{avl_tree | root: a, size: size - 1}
      {false, _} -> avl_tree
    end
  end

  @doc """
  Deletes an element equal to the given `value`.

  If the tree contains more than one element equal to `value`, deletes the last of them.

  If no element is found, returns the tree unchanged.

  ```
  iex> tree = [b: 21, a: 1, b: 22, c: 3, b: 23] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<[a: 1, b: 21, b: 22, b: 23, c: 3]>
  iex> AVLTree.delete_upper(tree, {:b, nil})
  #AVLTree<[a: 1, b: 21, b: 22, c: 3]>
  ```
  """
  @spec delete_upper(t(), value()) :: {:ok, t()} | :error
  def delete_upper(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    case Node.delete_upper(root, value, less) do
      {true, a} -> %{avl_tree | root: a, size: size - 1}
      {false, _} -> avl_tree
    end
  end

  @doc """
  Displays the tree in human readable form.

  ```
  iex> tree = 1..10 |> Enum.into(AVLTree.new())
  #AVLTree<[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]>
  iex> IO.puts AVLTree.view(tree)
  ```
  ```shell
     4
   ┌─┴───┐
   2     8
  ┌┴┐  ┌─┴─┐
  1 3  6   9
      ┌┴┐ ┌┴─┐
      5 7   10
  ```
  """
  @spec view(t()) :: String.t()
  def view(%__MODULE__{root: root}) do
    Node.view(root)
  end

  defimpl Enumerable do
    import AVLTree.Node, only: [iter_lower: 1, next: 1, value: 1]

    def reduce(%AVLTree{root: root}, {:cont, acc}, fun) do
      iter_lower(root) |> next() |> reduce({:cont, acc}, fun)
    end

    def reduce(iter, {state, acc}, fun) do
      case state do
        :halt ->
          {:halted, acc}

        :suspend ->
          {:suspended, acc, &reduce(iter, &1, fun)}

        :cont ->
          case iter do
            :none -> {:done, acc}
            {e, iter} -> reduce(next(iter), fun.(value(e), acc), fun)
          end
      end
    end

    def member?(%AVLTree{} = tree, value) do
      {:ok, AVLTree.member?(tree, value)}
    end

    def count(%AVLTree{size: size}) do
      {:ok, size}
    end

    def slice(_) do
      {:error, __MODULE__}
    end
  end

  defimpl Collectable do
    def into(original) do
      {
        original,
        fn
          tree, {:cont, value} -> AVLTree.put_upper(tree, value)
          tree, :done -> tree
          _, :halt -> :ok
        end
      }
    end
  end

  @opaque t() :: %__MODULE__{}
  @type value() :: term()
  @type less() :: (value(), value() -> boolean())
end

defimpl Inspect, for: AVLTree do
  def inspect(%AVLTree{} = tree, opts) do
    cnt = tree |> Enum.take(opts.limit + 1) |> Enum.to_list() |> inspect
    "#AVLTree<#{cnt}>"
  end
end
