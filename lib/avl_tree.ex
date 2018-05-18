defmodule AVLTree.Node do
  require Record

  Record.defrecord(:tree_node, __MODULE__, value: nil, height: 1, left: nil, right: nil)

  def put(nil, value, _less) do
    tree_node(value: value)
  end

  def put(tree_node(value: v, left: l, right: r) = a, value, less) do
    cond do
      less.(value, v) ->
        case put(l, value, less) do
          {:update, l} -> {:update, tree_node(a, left: l)}
          l -> balance(tree_node(a, left: l))
        end

      less.(v, value) ->
        case put(r, value, less) do
          {:update, r} -> {:update, tree_node(a, right: r)}
          r -> balance(tree_node(a, right: r))
        end

      true ->
        {:update, tree_node(a, value: value)}
    end
  end

  def put_upper(nil, value, _less) do
    put(nil, value, nil)
  end

  def put_upper(tree_node(value: v, left: l, right: r) = a, value, less) do
    balance(
      if less.(value, v) do
        tree_node(a, left: put_upper(l, value, less))
      else
        tree_node(a, right: put_upper(r, value, less))
      end
    )
  end

  def put_lower(nil, value, _less) do
    put(nil, value, nil)
  end

  def put_lower(tree_node(value: v, left: l, right: r) = a, value, less) do
    balance(
      if less.(v, value) do
        tree_node(a, right: put_lower(r, value, less))
      else
        tree_node(a, left: put_lower(l, value, less))
      end
    )
  end

  def get(nil, _value, _less) do
    nil
  end

  def get(tree_node(value: v, left: l, right: r), value, less) do
    cond do
      less.(value, v) -> get(l, value, less)
      less.(v, value) -> get(r, value, less)
      true -> v
    end
  end

  def get_lower(nil), do: nil

  def get_lower(tree_node(value: v, left: l)) do
    case l do
      nil -> v
      _ -> get_lower(l)
    end
  end

  def get_upper(nil), do: nil

  def get_upper(tree_node(value: v, right: r)) do
    case r do
      nil -> v
      _ -> get_upper(r)
    end
  end

  def height(nil) do
    0
  end

  def height(tree_node(height: h)) do
    h
  end

  defp fix_height(tree_node(left: left, right: right) = a) do
    tree_node(a, height: max(height(left), height(right)) + 1)
  end

  defp rotate_left(tree_node(right: tree_node(left: c) = b) = a) do
    fix_height(tree_node(b, left: fix_height(tree_node(a, right: c))))
  end

  defp rotate_right(tree_node(left: tree_node(right: c) = b) = a) do
    fix_height(tree_node(b, right: fix_height(tree_node(a, left: c))))
  end

  defp big_rotate_left(tree_node(right: b) = a) do
    rotate_left(tree_node(a, right: rotate_right(b)))
  end

  defp big_rotate_right(tree_node(left: b) = a) do
    rotate_right(tree_node(a, left: rotate_left(b)))
  end

  defp balance(a) do
    tree_node(left: l, right: r) = a = fix_height(a)

    cond do
      height(r) - height(l) == 2 ->
        if height(tree_node(r, :left)) <= height(tree_node(r, :right)) do
          rotate_left(a)
        else
          big_rotate_left(a)
        end

      height(l) - height(r) == 2 ->
        if height(tree_node(l, :right)) <= height(tree_node(l, :left)) do
          rotate_right(a)
        else
          big_rotate_right(a)
        end

      true ->
        a
    end
  end

  defp remove_min(tree_node(left: l, right: r) = a) do
    if l do
      {m, l} = remove_min(l)
      {m, balance(tree_node(a, left: l))}
    else
      {a, r}
    end
  end

  defp remove_max(tree_node(left: l, right: r) = a) do
    if r do
      {m, r} = remove_max(r)
      {m, balance(tree_node(a, right: r))}
    else
      {a, l}
    end
  end

  def remove(nil, _value, _less) do
    {false, nil}
  end

  def remove(tree_node(value: v, left: l, right: r) = a, value, less) do
    cond do
      less.(value, v) ->
        case remove(l, value, less) do
          {true, l} -> {true, balance(tree_node(a, left: l))}
          {false, _} -> {false, a}
        end

      less.(v, value) ->
        case remove(r, value, less) do
          {true, r} -> {true, balance(tree_node(a, right: r))}
          {false, _} -> {false, a}
        end

      true ->
        if height(r) > height(l) do
          if r == nil do
            {true, l}
          else
            {a, r} = remove_min(r)
            {true, balance(tree_node(a, left: l, right: r))}
          end
        else
          if l == nil do
            {true, r}
          else
            {a, l} = remove_max(l)
            {true, balance(tree_node(a, left: l, right: r))}
          end
        end
    end
  end
end

defmodule AVLTree do
  require AVLTree.Node
  alias AVLTree.Node

  defmodule Less do
    def less(a, b) do
      a < b
    end
  end

  defstruct root: nil, size: 0, less: &AVLTree.Less.less/2

  def new() do
    %AVLTree{}
  end

  def new(less) when is_function(less) do
    %AVLTree{less: less}
  end

  def get(%AVLTree{root: root, less: less}, value) do
    Node.get(root, value, less)
  end

  def get_lower(%AVLTree{root: root}) do
    Node.get_lower(root)
  end

  def get_upper(%AVLTree{root: root}) do
    Node.get_upper(root)
  end

  def has_value(%AVLTree{} = tree, value) do
    get(tree, value) != nil
  end

  def put(%AVLTree{root: root, size: size, less: less} = tree, value) do
    case Node.put(root, value, less) do
      {:update, root} -> %{tree | root: root}
      root -> %{tree | root: root, size: size + 1}
    end
  end

  def put_lower(%AVLTree{root: root, size: size, less: less} = tree, value) do
    %{tree | root: Node.put_lower(root, value, less), size: size + 1}
  end

  def put_upper(%AVLTree{root: root, size: size, less: less} = tree, value) do
    %{tree | root: Node.put_upper(root, value, less), size: size + 1}
  end

  def remove(%AVLTree{root: root, size: size, less: less} = tree, value) do
    case Node.remove(root, value, less) do
      {true, a} -> {true, %{tree | root: a, size: size - 1}}
      {false, _} -> {false, tree}
    end
  end

  defimpl Enumerable do
    alias AVLTree.Node

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

        [Node.tree_node(left: l) = c | p] ->
          reduce([l, {:left, c} | p], {:cont, acc}, fun)

        [{:left, Node.tree_node(value: v, right: r)} | p] ->
          reduce([r, :right | p], fun.(v, acc), fun)

        [:right | p] ->
          reduce(p, {:cont, acc}, fun)
      end
    end

    def member?(%AVLTree{} = tree, value) do
      {:ok, AVLTree.has_value(tree, value)}
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
end

defimpl Inspect, for: AVLTree do
  def inspect(%AVLTree{root: root, size: size}, _) do
    "#AVLTree<size: #{size}, height: #{AVLTree.Node.height(root)}>"
  end
end

defimpl String.Chars, for: AVLTree do
  import AVLTree.Node, only: [tree_node: 1]

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

  defp node_view(tree_node(value: v, left: nil, right: nil)) do
    v_str = inspect(v)
    v_width = String.length(v_str)
    {v_width, div(v_width, 2), [v_str]}
  end

  defp node_view(tree_node(value: v, left: l, right: r)) do
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
