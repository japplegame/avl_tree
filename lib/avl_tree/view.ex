defmodule AVLTree.Node.View do
  @moduledoc false

  def node_view(nil) do
    {1, 0, [" "]}
  end

  def node_view({v, _, nil, nil}) do
    v_str = inspect(v)
    v_width = String.length(v_str)
    {v_width, div(v_width, 2), [v_str]}
  end

  def node_view({v, _h, l, r}) do
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
end
