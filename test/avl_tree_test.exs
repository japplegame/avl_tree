defmodule AVLTreeTest do
  use ExUnit.Case
  doctest AVLTree

  use ExUnit.Case

  test "protocols" do
    tree1 = Enum.into([5, 9, 3, 8, 1, 6, 7], AVLTree.new())
    assert Enum.to_list(tree1) == [1, 3, 5, 6, 7, 8, 9]
    assert Enum.member?(tree1, 6)
    assert !Enum.member?(tree1, 10)
    tree2 = Enum.into([8, 4, 2, 5, 7, 2, 1, 3], AVLTree.new())
    assert Enum.to_list(tree2) == [1, 2, 2, 3, 4, 5, 7, 8]
    assert Enum.zip(tree1, tree2) == [{1, 1}, {3, 2}, {5, 2}, {6, 3}, {7, 4}, {8, 5}, {9, 7}]
  end

  test "put" do
    tree = Enum.into([5, 9, 3, 8, 1, 6, 7], AVLTree.new())
    assert Enum.to_list(tree) == [1, 3, 5, 6, 7, 8, 9]
    assert AVLTree.member?(tree, 3)
    assert !AVLTree.member?(tree, 2)

    assert inspect(tree) == "#AVLTree<size: 7, height: 4>"

    assert to_string(tree) ==
             Enum.join(
               [
                 "   5     ",
                 " ┌─┴───┐ ",
                 " 3     8 ",
                 "┌┴┐  ┌─┴┐",
                 "1    6  9",
                 "    ┌┴┐  ",
                 "      7  "
               ],
               "\n"
             )

    tree = Enum.into([11, 10, 12], tree)
    assert Enum.to_list(tree) == [1, 3, 5, 6, 7, 8, 9, 10, 11, 12]
    assert inspect(tree) == "#AVLTree<size: 10, height: 4>"

    assert to_string(tree) ==
             Enum.join(
               [
                 "       8      ",
                 "   ┌───┴─┐    ",
                 "   5    10    ",
                 " ┌─┴─┐  ┌┴─┐  ",
                 " 3   6  9 11  ",
                 "┌┴┐ ┌┴┐   ┌┴─┐",
                 "1     7     12"
               ],
               "\n"
             )

    tree = AVLTree.put(tree, 4)
    assert Enum.to_list(tree) == [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    assert inspect(tree) == "#AVLTree<size: 11, height: 4>"

    assert to_string(tree) ==
             Enum.join(
               [
                 "       8      ",
                 "   ┌───┴─┐    ",
                 "   5    10    ",
                 " ┌─┴─┐  ┌┴─┐  ",
                 " 3   6  9 11  ",
                 "┌┴┐ ┌┴┐   ┌┴─┐",
                 "1 4   7     12"
               ],
               "\n"
             )

    assert tree == AVLTree.put(tree, 7)
  end

  test "get" do
    tree =
      Enum.into(
        [
          {1, 10},
          {5, 50},
          {9, 90},
          {7, 70},
          {2, 20}
        ],
        AVLTree.new(fn {k1, _}, {k2, _} -> k1 < k2 end)
      )

    assert AVLTree.get(tree, {7, nil}) == {7, 70}
    assert AVLTree.get(tree, {5, nil}) == {5, 50}

    assert AVLTree.get_lower(tree) == {1, 10}
    assert AVLTree.get_upper(tree) == {9, 90}
  end

  test "put/delete lower/upper" do
    tree =
      Enum.into(
        [
          {1, 10},
          {5, 50},
          {9, 90},
          {7, 70},
          {2, 20}
        ],
        AVLTree.new(fn {k1, _}, {k2, _} -> k1 < k2 end)
      )

    assert Enum.to_list(tree) == [{1, 10}, {2, 20}, {5, 50}, {7, 70}, {9, 90}]
    assert inspect(tree) == "#AVLTree<size: 5, height: 3>"

    assert to_string(tree) ==
             Enum.join(
               [
                 "        {5, 50}        ",
                 "   ┌───────┴───────┐   ",
                 "{1, 10}         {9, 90}",
                 "  ┌┴───┐       ┌───┴┐  ",
                 "    {2, 20} {7, 70}    "
               ],
               "\n"
             )

    tree = AVLTree.put(tree, {7, 700})
    assert Enum.to_list(tree) == [{1, 10}, {2, 20}, {5, 50}, {7, 700}, {9, 90}]
    assert inspect(tree) == "#AVLTree<size: 5, height: 3>"

    assert to_string(tree) ==
             Enum.join(
               [
                 "        {5, 50}         ",
                 "   ┌───────┴────────┐   ",
                 "{1, 10}          {9, 90}",
                 "  ┌┴───┐        ┌───┴┐  ",
                 "    {2, 20} {7, 700}    "
               ],
               "\n"
             )

    assert AVLTree.put_lower(tree, {8, 80}) == AVLTree.put_upper(tree, {8, 80})
    assert AVLTree.put_lower(tree, {8, 80}) == AVLTree.put(tree, {8, 80})

    tree = AVLTree.put_lower(tree, {7, 71})
    tree = AVLTree.put_lower(tree, {7, 72})
    tree = AVLTree.put_lower(tree, {7, 73})

    assert Enum.to_list(tree) == [
             {1, 10},
             {2, 20},
             {5, 50},
             {7, 73},
             {7, 72},
             {7, 71},
             {7, 700},
             {9, 90}
           ]

    assert inspect(tree) == "#AVLTree<size: 8, height: 4>"

    assert to_string(tree) ==
             Enum.join(
               [
                 "        {5, 50}                    ",
                 "   ┌───────┴───────────────┐       ",
                 "{1, 10}                {7, 700}    ",
                 "  ┌┴───┐           ┌───────┴───┐   ",
                 "    {2, 20}     {7, 72}     {9, 90}",
                 "               ┌───┴───┐           ",
                 "            {7, 73} {7, 71}        "
               ],
               "\n"
             )

    tree = AVLTree.put_upper(tree, {7, 74})
    tree = AVLTree.put_upper(tree, {7, 75})
    tree = AVLTree.put_upper(tree, {7, 76})

    assert Enum.to_list(tree) == [
             {1, 10},
             {2, 20},
             {5, 50},
             {7, 73},
             {7, 72},
             {7, 71},
             {7, 700},
             {7, 74},
             {7, 75},
             {7, 76},
             {9, 90}
           ]

    assert to_string(tree) ==
             Enum.join(
               [
                 "                       {7, 700}                ",
                 "           ┌───────────────┴───────┐           ",
                 "        {5, 50}                 {7, 75}        ",
                 "   ┌───────┴───────┐           ┌───┴───────┐   ",
                 "{1, 10}         {7, 72}     {7, 74}     {9, 90}",
                 "  ┌┴───┐       ┌───┴───┐               ┌───┴┐  ",
                 "    {2, 20} {7, 73} {7, 71}         {7, 76}    "
               ],
               "\n"
             )
  end

  test "delete" do
    tree = Enum.into([5, 9, 3, 8, 1, 6, 7], AVLTree.new())
    assert match?(^tree, AVLTree.delete(tree, 4))
    assert :error = AVLTree.delete_exist(tree, 4)
    {:ok, tree} = AVLTree.delete_exist(tree, 3)

    assert Enum.to_list(tree) == [1, 5, 6, 7, 8, 9]
    assert inspect(tree) == "#AVLTree<size: 6, height: 3>"

    assert to_string(tree) ==
             Enum.join(
               [
                 "   6   ",
                 " ┌─┴─┐ ",
                 " 5   8 ",
                 "┌┴┐ ┌┴┐",
                 "1   7 9"
               ],
               "\n"
             )

    tree = AVLTree.delete(tree, 1)
    assert Enum.to_list(tree) == [5, 6, 7, 8, 9]
    assert inspect(tree) == "#AVLTree<size: 5, height: 3>"

    assert to_string(tree) ==
             Enum.join(
               [
                 " 6   ",
                 "┌┴─┐ ",
                 "5  8 ",
                 "  ┌┴┐",
                 "  7 9"
               ],
               "\n"
             )

    tree = AVLTree.delete(tree, 8)
    assert Enum.to_list(tree) == [5, 6, 7, 9]
    assert inspect(tree) == "#AVLTree<size: 4, height: 3>"

    assert to_string(tree) ==
             Enum.join(
               [
                 " 6   ",
                 "┌┴─┐ ",
                 "5  7 ",
                 "  ┌┴┐",
                 "    9"
               ],
               "\n"
             )

    tree = Enum.into([3, 1, 2, 4, 8, 0], tree)
    assert Enum.to_list(tree) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    assert inspect(tree) == "#AVLTree<size: 10, height: 4>"

    assert to_string(tree) ==
             Enum.join(
               [
                 "       6   ",
                 "   ┌───┴─┐ ",
                 "   3     8 ",
                 " ┌─┴─┐  ┌┴┐",
                 " 1   5  7 9",
                 "┌┴┐ ┌┴┐    ",
                 "0 2 4      "
               ],
               "\n"
             )

    tree1 = AVLTree.delete(tree, 6)
    assert Enum.to_list(tree1) == [0, 1, 2, 3, 4, 5, 7, 8, 9]
    assert inspect(tree1) == "#AVLTree<size: 9, height: 4>"

    assert to_string(tree1) ==
             Enum.join(
               [
                 "     5   ",
                 "   ┌─┴─┐ ",
                 "   3   8 ",
                 " ┌─┴┐ ┌┴┐",
                 " 1  4 7 9",
                 "┌┴┐      ",
                 "0 2      "
               ],
               "\n"
             )

    tree = Enum.into([0, 3, 2, 1, 4, 8, 7, 9, 5, 6, 11, 12, 10, 14, 13, 15], AVLTree.new())
    tree = AVLTree.delete(tree, 4)
    assert Enum.to_list(tree) == [0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    assert inspect(tree) == "#AVLTree<size: 15, height: 5>"

    assert to_string(tree) ==
             Enum.join(
               [
                 "     5              ",
                 "   ┌─┴──────┐       ",
                 "   2       11       ",
                 " ┌─┴┐  ┌────┴──┐    ",
                 " 0  3  7      13    ",
                 "┌┴┐   ┌┴─┐    ┌┴─┐  ",
                 "  1   6  9   12 14  ",
                 "        ┌┴─┐    ┌┴─┐",
                 "        8 10      15"
               ],
               "\n"
             )
  end
end
