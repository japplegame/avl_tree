defmodule AVLTree do
  @moduledoc """
  Pure Elixir [AVL tree](https://en.wikipedia.org/wiki/AVL_tree) implementation.

  This data structure is very similar to `MapSet`, but unlike the latter,
  elements in the AVL tree are always sorted in ascending or descending order.

  In addition (thanks to custom sorting), the AVL tree can perform like a sorted map.

  `AVLTree` can store duplicate values.
  It is important to understand that duplicate values are not necessarily the same.

  Elements `a` and `b` are considered equal if they satisfy the following condition:

  `f(a, b) == false and f(b, a) == false`, where `f(x, y)` is ordering function

  For example, if the ordering function is `fn {a, _}, {b, _} -> a < b end`,
  then the elements `{1, 10}` and `{1, 20}` will be considered equal, although they are not actually equal.

  By default, ordering function for `AVLTree` is `Kernel.</2`.

  ## Features

  - custom ordering function;
  - support for duplicate elements;
  - `Collectable`, `Enumerable`, `Inspect`, `String.Chars` protocols;
  - human readable visualization.

  ## Inserting values

  By default, inserted elements will be sorted in ascending order.
  ```
  iex> tree = AVLTree.new()
  #AVLTree<size: 0, height: 0>
  iex> tree = AVLTree.put(tree, 5)
  #AVLTree<size: 1, height: 1>
  iex> tree = [2, 1, 3] |> Enum.into(tree)
  #AVLTree<size: 4, height: 3>
  iex> Enum.to_list(tree)
  [1, 2, 3, 5]
  ```

  ## Descending order

  ```
  iex> tree = AVLTree.new(:desc)
  #AVLTree<size: 0, height: 0>
  iex> tree = AVLTree.put(tree, 5)
  #AVLTree<size: 1, height: 1>
  iex> tree = [2, 1, 3] |> Enum.into(tree)
  #AVLTree<size: 4, height: 3>
  iex> Enum.to_list(tree)
  [5, 3, 2, 1]
  ```

  ## Custom ordering function

  Example of a tree with tuples as elements, sorted by the first field
  ```
  iex> tree = AVLTree.new(fn {a, _}, {b, _} -> a < b end)
  #AVLTree<size: 0, height: 0>
  iex> [{2, "A"}, {3, "B"}, {1, "C"}] |> Enum.into(tree) |> Enum.to_list()
  [{1, "C"}, {2, "A"}, {3, "B"}]
  ```
  """
  require __MODULE__.Node
  alias __MODULE__.Node

  defstruct root: nil, size: 0, less: &Kernel.</2

  @doc """
  Creates a new tree with default ascending order.

  ```
  iex> [3, 1, 4, 2] |> Enum.into(AVLTree.new()) |> Enum.to_list()
  [1, 2, 3, 4]
  ```
  """
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @doc """
  Creates a new tree with the given `ordering`.

  ```
  iex> [3, 1, 4, 2] |> Enum.into(AVLTree.new(:asc)) |> Enum.to_list()
  [1, 2, 3, 4]
  iex> [3, 1, 4, 2] |> Enum.into(AVLTree.new(:desc)) |> Enum.to_list()
  [4, 3, 2, 1]
  iex> [3, 1, 4, 2] |> Enum.into(AVLTree.new(fn a, b -> a > b end)) |> Enum.to_list()
  [4, 3, 2, 1]
  ```
  """
  @spec new(:asc | :desc | (value(), value() -> boolean())) :: t()
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
  Retrieves an element equal to `value`.

  Returns `nil` if nothing was found.

  ```
  iex> tree = AVLTree.new(fn {a, _}, {b, _} -> a < b end)
  #AVLTree<size: 0, height: 0>
  iex> tree = [a: "A", c: "C", d: "D", b: "B"] |> Enum.into(tree)
  #AVLTree<size: 4, height: 3>
  iex> AVLTree.get(tree, {:c, nil})
  {:c, "C"}
  iex> AVLTree.get(tree, {10, nil})
  nil
  ```

  """
  @spec get(t(), term()) :: value() | nil
  def get(%__MODULE__{root: root, less: less}, value) do
    Node.get(root, value, less)
  end

  @doc """
  Retrieves an element equal to `value`.

  Returns `defailt` if nothing was found.

  ```
  iex> tree = AVLTree.new(fn {a, _}, {b, _} -> a < b end)
  #AVLTree<size: 0, height: 0>
  iex> tree = [a: "A", c: "C", d: "D", b: "B"] |> Enum.into(tree)
  #AVLTree<size: 4, height: 3>
  iex> AVLTree.get(tree, {:c, nil}, :error)
  {:c, "C"}
  iex> AVLTree.get(tree, {10, nil}, :error)
  :error
  ```
  """
  @spec get(t(), term(), term()) :: value()
  def get(%__MODULE__{root: root, less: less}, value, default) do
    case Node.get(root, value, less) do
      nil -> default
      value -> value
    end
  end

  @doc """
  Retrieves the lowest value.

  ```
  iex> tree = [3, 2, 4, 6] |> Enum.into(AVLTree.new())
  #AVLTree<size: 4, height: 3>
  iex> AVLTree.get_lower(tree)
  2
  ```
  """
  @spec get_lower(t()) :: value()
  def get_lower(%__MODULE__{root: root}) do
    Node.get_lower(root)
  end

  @doc """
  Retrieves the uppest value.

  ```
  iex> tree = [3, 2, 4, 6] |> Enum.into(AVLTree.new())
  #AVLTree<size: 4, height: 3>
  iex> AVLTree.get_upper(tree)
  6
  ```
  """
  @spec get_upper(t()) :: value()
  def get_upper(%__MODULE__{root: root}) do
    Node.get_upper(root)
  end

  @doc """
  Checks if `avl_tree` contains an element equal to `value`

  ```
  iex> tree = [3, 2, 4, 6] |> Enum.into(AVLTree.new())
  #AVLTree<size: 4, height: 3>
  iex> AVLTree.member?(tree, 4)
  true
  iex> AVLTree.member?(tree, 1)
  false
  ```
  """
  @spec member?(t(), term()) :: boolean()
  def member?(%__MODULE__{root: root, less: less}, value) do
    Node.get(root, value, less) != nil
  end

  @doc """
  Puts the given `value` in `avl_tree` with duplicate replacement.

  ```
  iex> tree = [b: 2, a: 1, c: 3] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<size: 3, height: 2>
  iex> AVLTree.put(tree, {:d, 4}) |> Enum.to_list()
  [a: 1, b: 2, c: 3, d: 4]
  iex> AVLTree.put(tree, {:a, 11}) |> Enum.to_list()
  [a: 11, b: 2, c: 3]
  ```
  """
  def put(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    case Node.put(root, value, less) do
      {:update, root} -> %{avl_tree | root: root}
      root -> %{avl_tree | root: root, size: size + 1}
    end
  end

  @doc """
  Puts the given `value` in `avl_tree` without replacing duplicates, in the reverse insertion order.

  ```
  iex> tree = [b: 2, a: 1, c: 3] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<size: 3, height: 2>
  iex> (tree = AVLTree.put(tree, {:d, 4})) |> Enum.to_list()
  [a: 1, b: 2, c: 3, d: 4]
  iex> (tree = AVLTree.put_lower(tree, {:a, 2})) |> Enum.to_list()
  [a: 2, a: 1, b: 2, c: 3, d: 4]
  iex> (tree = AVLTree.put_lower(tree, {:a, 1})) |> Enum.to_list()
  [a: 1, a: 2, a: 1, b: 2, c: 3, d: 4]
  iex> AVLTree.put_lower(tree, {:b, 3}) |> Enum.to_list()
  [a: 1, a: 2, a: 1, b: 3, b: 2, c: 3, d: 4]
  ```
  """
  def put_lower(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    %{avl_tree | root: Node.put_lower(root, value, less), size: size + 1}
  end

  @doc """
  Puts the given `value` in `avl_tree` without replacing duplicates, in the insertion order.

  ```
  iex> tree = [b: 2, a: 1, c: 3] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end))
  #AVLTree<size: 3, height: 2>
  iex> (tree = AVLTree.put(tree, {:d, 4})) |> Enum.to_list()
  [a: 1, b: 2, c: 3, d: 4]
  iex> (tree = AVLTree.put_upper(tree, {:a, 2})) |> Enum.to_list()
  [a: 1, a: 2, b: 2, c: 3, d: 4]
  iex> (tree = AVLTree.put_upper(tree, {:a, 1})) |> Enum.to_list()
  [a: 1, a: 2, a: 1, b: 2, c: 3, d: 4]
  iex> AVLTree.put_upper(tree, {:b, 3}) |> Enum.to_list()
  [a: 1, a: 2, a: 1, b: 2, b: 3, c: 3, d: 4]
  ```

  `Enum.into/2` uses `put_upper/2`:

  ```
  iex> [a: 1, c: 3, a: 3, b: 2, a: 2] |> Enum.into(AVLTree.new(fn {a, _}, {b, _} -> a < b end)) |> Enum.to_list()
  [a: 1, a: 3, a: 2, b: 2, c: 3]
  ```
  """
  def put_upper(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    %{avl_tree | root: Node.put_upper(root, value, less), size: size + 1}
  end

  @doc """
  Deletes element equal to the given `value`.

  If element was not found, returns tree unchanged.

  ```
  iex> tree = [3, 2, 1, 4] |> Enum.into(AVLTree.new())
  #AVLTree<size: 4, height: 3>
  iex> AVLTree.delete(tree, 3) |> Enum.to_list()
  [1, 2, 4]
  iex> AVLTree.delete(tree, 5) |> Enum.to_list()
  [1, 2, 3, 4]
  ```
  """
  def delete(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    case Node.delete(root, value, less) do
      {true, a} -> %{avl_tree | root: a, size: size - 1}
      {false, _} -> avl_tree
    end
  end

  @doc """
  Deletes existing element equal to the given `value`.

  If the element was deleted, returns `{:ok, new_tree}`, otherwise `:error`

  ```
  iex> tree = [3, 2, 1, 4] |> Enum.into(AVLTree.new())
  #AVLTree<size: 4, height: 3>
  iex> {:ok, new_tree} = AVLTree.delete_exist(tree, 3)
  iex> Enum.to_list(new_tree)
  [1, 2, 4]
  iex> AVLTree.delete_exist(tree, 5)
  :error
  ```
  """
  def delete_exist(%__MODULE__{root: root, size: size, less: less} = avl_tree, value) do
    case Node.delete(root, value, less) do
      {true, a} -> {:ok, %{avl_tree | root: a, size: size - 1}}
      {false, _} -> :error
    end
  end

  defimpl Enumerable do
    def reduce(%AVLTree{root: root}, {:cont, acc}, fun) do
      reduce([root], {:cont, acc}, fun)
    end

    def reduce(_, {:halt, acc}, _) do
      {:halted, acc}
    end

    def reduce(path, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(path, &1, fun)}
    end

    def reduce(path, {:cont, acc}, fun) do
      case path do
        [] ->
          {:done, acc}

        [nil | p] ->
          reduce(p, {:cont, acc}, fun)

        [{_v, _h, l, _r} = c | p] ->
          reduce([l, {:left, c} | p], {:cont, acc}, fun)

        [{:left, {v, _h, _l, r}} | p] ->
          reduce([r, :right | p], fun.(v, acc), fun)

        [:right | p] ->
          reduce(p, {:cont, acc}, fun)
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
end

defimpl Inspect, for: AVLTree do
  def inspect(%AVLTree{root: root, size: size}, _) do
    "#AVLTree<size: #{size}, height: #{AVLTree.Node.height(root)}>"
  end
end

defimpl String.Chars, for: AVLTree do
  defp merge(_, _, [], []) do
    []
  end

  defp merge(lw, rw, [], [rh | rt]) do
    [
      String.duplicate(" ", lw) <> " " <> String.pad_trailing(rh, rw)
      | merge(lw, rw, [], rt)
    ]
  end

  defp merge(lw, rw, [lh | lt], []) do
    [
      String.pad_leading(lh, lw) <> " " <> String.duplicate(" ", rw)
      | merge(lw, rw, lt, [])
    ]
  end

  defp merge(lw, rw, [lh | lt], [rh | rt]) do
    [
      String.pad_leading(lh, lw) <> " " <> String.pad_trailing(rh, rw)
      | merge(lw, rw, lt, rt)
    ]
  end

  defp node_view(nil) do
    {1, 0, [" "]}
  end

  defp node_view({v, _, nil, nil}) do
    v_str = inspect(v)
    v_width = String.length(v_str)
    {v_width, div(v_width, 2), [v_str]}
  end

  defp node_view({v, _h, l, r}) do
    v_str = inspect(v)
    v_width = String.length(v_str)
    v_left_width = div(v_width, 2)
    v_right_width = v_width - v_left_width - 1

    {l_width, l_head, l_canvas} = node_view(l)
    {r_width, r_head, r_canvas} = node_view(r)

    left_width = max(v_left_width, l_width)
    right_width = max(v_right_width, r_width)

    width = left_width + right_width + 1

    left_connector =
      String.pad_leading("┌" <> String.duplicate("─", l_width - l_head - 1), left_width)

    right_connector = String.pad_trailing(String.duplicate("─", r_head) <> "┐", right_width)

    {
      width,
      left_width,
      [
        String.pad_trailing(String.pad_leading(v_str, left_width + v_right_width + 1), width),
        left_connector <> "┴" <> right_connector
        | merge(left_width, right_width, l_canvas, r_canvas)
      ]
    }
  end

  def to_string(%AVLTree{root: root}) do
    {_, _, canvas} = node_view(root)
    Enum.join(canvas, "\n")
  end
end
