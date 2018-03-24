defmodule AVLTree do
  defmodule Less do
    def less(a, b) do
      a < b
    end
  end

  defmodule Node do
    defstruct value: nil, left: nil, right: nil, height: 1

    def put(nil, value, _less) do
      %Node{value: value}
    end

    def put(%Node{left: l, right: r} = a, value, less) do
      cond do
        less.(value, a.value) ->
          case put(l, value, less) do
            {:update, l} -> {:update, %{a | left: l}}
            l -> balance(%{a | left: l})
          end

        less.(a.value, value) ->
          case put(r, value, less) do
            {:update, r} -> {:update, %{a | right: r}}
            r -> balance(%{a | right: r})
          end

        true ->
          {:update, %{a | value: value}}
      end
    end

    def put_right(nil, value, _less) do
      put(nil, value, nil)
    end

    def put_right(%Node{left: l, right: r} = a, value, less) do
      balance(
        if less.(value, a.value) do
          %{a | left: put_right(l, value, less)}
        else
          %{a | right: put_right(r, value, less)}
        end
      )
    end

    def put_left(nil, value, _less) do
      put(nil, value, nil)
    end

    def put_left(%Node{left: l, right: r} = a, value, less) do
      balance(
        if less.(a.value, value) do
          %{a | right: put_left(r, value, less)}
        else
          %{a | left: put_left(l, value, less)}
        end
      )
    end

    def get(nil, _value, _less) do
      nil
    end

    def get(%Node{left: l, right: r, value: node_value}, value, less) do
      cond do
        less.(value, node_value) -> get(l, value, less)
        less.(node_value, value) -> get(r, value, less)
        true -> node_value
      end
    end

    defp height(nil) do
      0
    end

    defp height(%Node{height: height}) do
      height
    end

    defp fix_height(%Node{left: left, right: right} = a) do
      %{a | height: max(height(left), height(right)) + 1}
    end

    defp rotate_left(%Node{right: %Node{left: c} = b} = a) do
      fix_height(%{b | left: fix_height(%{a | right: c})})
    end

    defp rotate_right(%Node{left: %Node{right: c} = b} = a) do
      fix_height(%{b | right: fix_height(%{a | left: c})})
    end

    defp big_rotate_left(%Node{right: %Node{} = b} = a) do
      rotate_left(%{a | right: rotate_right(b)})
    end

    defp big_rotate_right(%Node{left: %Node{} = b} = a) do
      rotate_right(%{a | left: rotate_left(b)})
    end

    defp balance(%Node{} = a) do
      %{left: l, right: r} = a = fix_height(a)

      cond do
        height(r) - height(l) == 2 ->
          if height(r.left) <= height(r.right) do
            rotate_left(a)
          else
            big_rotate_left(a)
          end

        height(l) - height(r) == 2 ->
          if height(l.right) <= height(l.left) do
            rotate_right(a)
          else
            big_rotate_right(a)
          end

        true ->
          a
      end
    end

    defp remove_min(%Node{left: l, right: r} = a) do
      if l do
        {m, l} = remove_min(l)
        {m, balance(%{a | left: l})}
      else
        {a, r}
      end
    end

    defp remove_max(%Node{left: l, right: r} = a) do
      if r do
        {m, r} = remove_max(r)
        {m, balance(%{a | right: r})}
      else
        {a, l}
      end
    end

    def remove(nil, _value, _less) do
      {false, nil}
    end

    def remove(%Node{left: l, right: r, value: node_value} = a, value, less) do
      cond do
        less.(value, node_value) ->
          case remove(l, value, less) do
            {true, l} -> {true, balance(%{a | left: l})}
            {false, _} -> {false, a}
          end

        less.(node_value, value) ->
          case remove(r, value, less) do
            {true, r} -> {true, balance(%{a | right: r})}
            {false, _} -> {false, a}
          end

        true ->
          if height(r) > height(l) do
            if r == nil do
              {true, l}
            else
              {a, r} = remove_min(r)
              {true, balance(%{a | left: l, right: r})}
            end
          else
            if l == nil do
              {true, r}
            else
              {a, l} = remove_max(l)
              {true, balance(%{a | left: l, right: r})}
            end
          end
      end
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

  def has_value(%AVLTree{} = tree, value) do
    get(tree, value) != nil
  end

  def put(%AVLTree{root: root, size: size, less: less} = tree, value) do
    case Node.put(root, value, less) do
      {:update, root} -> %{tree | root: root}
      root -> %{tree | root: root, size: size + 1}
    end
  end

  def put_left(%AVLTree{root: root, size: size, less: less} = tree, value) do
    %{tree | root: Node.put_left(root, value, less), size: size + 1}
  end

  def put_right(%AVLTree{root: root, size: size, less: less} = tree, value) do
    %{tree | root: Node.put_right(root, value, less), size: size + 1}
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

        [%Node{left: l} = c | p] ->
          reduce([l, {:left, c} | p], {:cont, acc}, fun)

        [{:left, %Node{right: r, value: v} = c} | p] ->
          reduce([r, {:right, c} | p], fun.(v, acc), fun)

        [{:right, %Node{}} | p] ->
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
          tree, {:cont, value} -> AVLTree.put_right(tree, value)
          tree, :done -> tree
          _, :halt -> :ok
        end
      }
    end
  end
end
