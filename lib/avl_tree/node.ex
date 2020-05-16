defmodule AVLTree.Node do
  @moduledoc false
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

  defp delete_min(tree_node(left: l, right: r) = a) do
    if l do
      {m, l} = delete_min(l)
      {m, balance(tree_node(a, left: l))}
    else
      {a, r}
    end
  end

  defp delete_max(tree_node(left: l, right: r) = a) do
    if r do
      {m, r} = delete_max(r)
      {m, balance(tree_node(a, right: r))}
    else
      {a, l}
    end
  end

  def delete(nil, _value, _less) do
    {false, nil}
  end

  def delete(tree_node(value: v, left: l, right: r) = a, value, less) do
    cond do
      less.(value, v) ->
        case delete(l, value, less) do
          {true, l} -> {true, balance(tree_node(a, left: l))}
          {false, _} -> {false, a}
        end

      less.(v, value) ->
        case delete(r, value, less) do
          {true, r} -> {true, balance(tree_node(a, right: r))}
          {false, _} -> {false, a}
        end

      true ->
        if height(r) > height(l) do
          if r == nil do
            {true, l}
          else
            {a, r} = delete_min(r)
            {true, balance(tree_node(a, left: l, right: r))}
          end
        else
          if l == nil do
            {true, r}
          else
            {a, l} = delete_max(l)
            {true, balance(tree_node(a, left: l, right: r))}
          end
        end
    end
  end
end
