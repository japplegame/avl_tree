defmodule AVLTree.Node do
  @moduledoc false

  @compile {:inline,
            value: 1,
            height: 1,
            fix_height: 1,
            rotate_left: 1,
            rotate_right: 1,
            big_rotate_left: 1,
            big_rotate_right: 1,
            balance: 1}

  def put(nil, value, _less), do: {value, 1, nil, nil}

  def put({v, h, l, r}, value, less) do
    cond do
      less.(value, v) ->
        case put(l, value, less) do
          {:update, l} -> {:update, {v, h, l, r}}
          l -> balance({v, h, l, r})
        end

      less.(v, value) ->
        case put(r, value, less) do
          {:update, r} -> {:update, {v, h, l, r}}
          r -> balance({v, h, l, r})
        end

      true ->
        {:update, {value, h, l, r}}
    end
  end

  def put_lower(nil, value, _less), do: {value, 1, nil, nil}

  def put_lower({v, h, l, r}, value, less) do
    balance(
      if less.(v, value) do
        {v, h, l, put_lower(r, value, less)}
      else
        {v, h, put_lower(l, value, less), r}
      end
    )
  end

  def put_upper(nil, value, _less), do: {value, 1, nil, nil}

  def put_upper({v, h, l, r}, value, less) do
    balance(
      if less.(value, v) do
        {v, h, put_upper(l, value, less), r}
      else
        {v, h, l, put_upper(r, value, less)}
      end
    )
  end

  def member?(nil, _value, _less), do: false

  def member?({v, _h, l, r}, value, less) do
    cond do
      less.(value, v) -> member?(l, value, less)
      less.(v, value) -> member?(r, value, less)
      true -> true
    end
  end

  def get(nil, _value, default, _less), do: default

  def get({v, _h, l, r}, value, default, less) do
    cond do
      less.(value, v) -> get(l, value, default, less)
      less.(v, value) -> get(r, value, default, less)
      true -> v
    end
  end

  def get_first(nil, default), do: default
  def get_first({v, _h, nil, _r}, _default), do: v
  def get_first({_v, _h, l, _r}, default), do: get_first(l, default)

  def get_last(nil, default), do: default
  def get_last({v, _h, _l, nil}, _default), do: v
  def get_last({_v, _h, _l, r}, default), do: get_last(r, default)

  def get_lower(nil, _value, default, _less), do: default

  def get_lower({v, _h, l, r}, value, default, less) do
    case less.(v, value) do
      true ->
        get_lower(r, value, default, less)

      false ->
        case get_lower(l, value, default, less) do
          nil ->
            case less.(value, v) do
              true -> default
              false -> v
            end

          value ->
            value
        end
    end
  end

  def get_upper(nil, _value, default, _less), do: default

  def get_upper({v, _h, l, r}, value, default, less) do
    case less.(value, v) do
      true ->
        get_upper(l, value, default, less)

      false ->
        case get_upper(r, value, default, less) do
          nil ->
            case less.(v, value) do
              true -> default
              false -> v
            end

          value ->
            value
        end
    end
  end

  def height(nil), do: 0
  def height({_v, h, _l, _r}), do: h
  def value({v, _h, _l, _r}), do: v

  def delete(nil, _value, _less), do: {false, nil}

  def delete({v, h, l, r} = a, value, less) do
    cond do
      less.(value, v) ->
        case delete(l, value, less) do
          {true, l} -> {true, balance({v, h, l, r})}
          {false, _} -> {false, a}
        end

      less.(v, value) ->
        case delete(r, value, less) do
          {true, r} -> {true, balance({v, h, l, r})}
          {false, _} -> {false, a}
        end

      true ->
        {true, delete_node(a)}
    end
  end

  def delete_lower(nil, _value, _less), do: {false, nil}

  def delete_lower({v, h, l, r} = a, value, less) do
    case less.(v, value) do
      true ->
        case delete_lower(r, value, less) do
          {true, r} -> {true, balance({v, h, l, r})}
          {false, _} -> {false, a}
        end

      false ->
        case delete_lower(l, value, less) do
          {true, l} ->
            {true, balance({v, h, l, r})}

          {false, _} ->
            case less.(value, v) do
              true -> {false, a}
              false -> {true, delete_node(a)}
            end
        end
    end
  end

  def delete_upper(nil, _value, _less), do: {false, nil}

  def delete_upper({v, h, l, r} = a, value, less) do
    case less.(value, v) do
      true ->
        case delete_upper(l, value, less) do
          {true, l} -> {true, balance({v, h, l, r})}
          {false, _} -> {false, a}
        end

      false ->
        case delete_upper(r, value, less) do
          {true, r} ->
            {true, balance({v, h, l, r})}

          {false, _} ->
            case less.(v, value) do
              true -> {false, a}
              false -> {true, delete_node(a)}
            end
        end
    end
  end

  def iter_lower(root), do: iter_lower_impl(root, [])

  def iter_lower_impl({_v, _h, l, _r} = a, iter), do: iter_lower_impl(l, [a | iter])
  def iter_lower_impl(nil, iter), do: iter

  def next([{_v, _h, _, r} = n | tail]), do: {n, iter_lower_impl(r, tail)}
  def next([]), do: :none

  def view(root) do
    {_, _, canvas} = __MODULE__.View.node_view(root)
    Enum.join(canvas, "\n")
  end

  defp fix_height({v, _h, l, r}) do
    {v, max(height(l), height(r)) + 1, l, r}
  end

  defp rotate_left({v, h, l, {rv, rh, rl, rr}}) do
    fix_height({rv, rh, fix_height({v, h, l, rl}), rr})
  end

  defp rotate_right({v, h, {lv, lh, ll, lr}, r}) do
    fix_height({lv, lh, ll, fix_height({v, h, lr, r})})
  end

  defp big_rotate_left({v, h, l, r}) do
    rotate_left({v, h, l, rotate_right(r)})
  end

  defp big_rotate_right({v, h, l, r}) do
    rotate_right({v, h, rotate_left(l), r})
  end

  defp balance(a) do
    a = fix_height(a)
    {_v, _h, l, r} = a

    cond do
      height(r) - height(l) == 2 ->
        {_rv, _rh, rl, rr} = r

        if height(rl) <= height(rr) do
          rotate_left(a)
        else
          big_rotate_left(a)
        end

      height(l) - height(r) == 2 ->
        {_lv, _lh, ll, lr} = l

        if height(lr) <= height(ll) do
          rotate_right(a)
        else
          big_rotate_right(a)
        end

      true ->
        a
    end
  end

  defp delete_node({_v, _h, l, r}) do
    if height(r) > height(l) do
      {{v, h, _l, _r}, r} = delete_min(r)
      balance({v, h, l, r})
    else
      if l == nil do
        r
      else
        {{v, h, _l, _r}, l} = delete_max(l)
        balance({v, h, l, r})
      end
    end
  end

  defp delete_min({v, h, l, r} = a) do
    if l do
      {m, l} = delete_min(l)
      {m, balance({v, h, l, r})}
    else
      {a, r}
    end
  end

  defp delete_max({v, h, l, r} = a) do
    if r do
      {m, r} = delete_max(r)
      {m, balance({v, h, l, r})}
    else
      {a, l}
    end
  end
end
