defmodule AVLTree.Node do
  @moduledoc false

  def put(nil, value, _less) do
    {value, 1, nil, nil}
  end

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

  def put_upper(nil, value, _less) do
    put(nil, value, nil)
  end

  def put_upper({v, h, l, r}, value, less) do
    balance(
      if less.(value, v) do
        {v, h, put_upper(l, value, less), r}
      else
        {v, h, l, put_upper(r, value, less)}
      end
    )
  end

  def put_lower(nil, value, _less) do
    put(nil, value, nil)
  end

  def put_lower({v, h, l, r}, value, less) do
    balance(
      if less.(v, value) do
        {v, h, l, put_lower(r, value, less)}
      else
        {v, h, put_lower(l, value, less), r}
      end
    )
  end

  def get(nil, _value, _less) do
    nil
  end

  def get({v, _h, l, r}, value, less) do
    cond do
      less.(value, v) -> get(l, value, less)
      less.(v, value) -> get(r, value, less)
      true -> v
    end
  end

  def get_lower(nil), do: nil

  def get_lower({v, _h, l, _r}) do
    case l do
      nil -> v
      _ -> get_lower(l)
    end
  end

  def get_upper(nil), do: nil

  def get_upper({v, _h, _l, r}) do
    case r do
      nil -> v
      _ -> get_upper(r)
    end
  end

  def height(nil) do
    0
  end

  def height({_v, h, _l, _r}) do
    h
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

  def delete(nil, _value, _less) do
    {false, nil}
  end

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
        if height(r) > height(l) do
          if r == nil do
            {true, l}
          else
            {{v, h, _l, _r}, r} = delete_min(r)
            {true, balance({v, h, l, r})}
          end
        else
          if l == nil do
            {true, r}
          else
            {{v, h, _l, _r}, l} = delete_max(l)
            {true, balance({v, h, l, r})}
          end
        end
    end
  end
end
