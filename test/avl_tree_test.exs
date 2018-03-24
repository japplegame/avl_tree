defmodule AVLTreeTest1 do
  use ExUnit.Case
  doctest AVLTree

  use ExUnit.Case

  test "protocols" do
    tree1 = Enum.into([5, 9, 3, 8, 1, 6, 7], AVLTree.new())
    assert Enum.to_list(tree1) == [1, 3, 5, 6, 7, 8, 9]
    tree2 = Enum.into([8, 4, 2, 5, 7, 2, 1, 3], AVLTree.new())
    assert Enum.to_list(tree2) == [1, 2, 2, 3, 4, 5, 7, 8]
    assert Enum.zip(tree1, tree2) == [{1, 1}, {3, 2}, {5, 2}, {6, 3}, {7, 4}, {8, 5}, {9, 7}]
  end

  test "put (tree layout)" do
    tree = Enum.into([5, 9, 3, 8, 1, 6, 7], AVLTree.new())
    assert Enum.to_list(tree) == [1, 3, 5, 6, 7, 8, 9]
    assert Enum.member?(tree, 3)
    assert !Enum.member?(tree, 2)

    assert match?(
             %{
               root: %{
                 height: 4,
                 left: %{
                   height: 2,
                   left: %{height: 1, left: nil, right: nil, value: 1},
                   right: nil,
                   value: 3
                 },
                 right: %{
                   height: 3,
                   left: %{
                     height: 2,
                     left: nil,
                     right: %{height: 1, left: nil, right: nil, value: 7},
                     value: 6
                   },
                   right: %{height: 1, left: nil, right: nil, value: 9},
                   value: 8
                 },
                 value: 5
               },
               size: 7
             },
             tree
           )

    tree = Enum.into([11, 10, 12], tree)

    assert match?(
             %{
               root: %{
                 height: 4,
                 left: %{
                   height: 3,
                   left: %{
                     height: 2,
                     left: %{height: 1, left: nil, right: nil, value: 1},
                     right: nil,
                     value: 3
                   },
                   right: %{
                     height: 2,
                     left: nil,
                     right: %{height: 1, left: nil, right: nil, value: 7},
                     value: 6
                   },
                   value: 5
                 },
                 right: %{
                   height: 3,
                   left: %{height: 1, left: nil, right: nil, value: 9},
                   right: %{
                     height: 2,
                     left: nil,
                     right: %{height: 1, left: nil, right: nil, value: 12},
                     value: 11
                   },
                   value: 10
                 },
                 value: 8
               }
             },
             tree
           )

    assert tree == AVLTree.put(tree, 7)
    assert Enum.to_list(tree) == [1, 3, 5, 6, 7, 8, 9, 10, 11, 12]
  end

  test "put left/right (tree layout)" do
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

    assert match?(
             %{
               root: %{
                 height: 3,
                 left: %{
                   height: 2,
                   left: nil,
                   right: %{height: 1, left: nil, right: nil, value: {2, 20}},
                   value: {1, 10}
                 },
                 right: %{
                   height: 2,
                   left: %{height: 1, left: nil, right: nil, value: {7, 70}},
                   right: nil,
                   value: {9, 90}
                 },
                 value: {5, 50}
               },
               size: 5
             },
             tree
           )

    tree = AVLTree.put(tree, {7, 700})

    assert match?(
             %{
               root: %{
                 height: 3,
                 left: %{
                   height: 2,
                   left: nil,
                   right: %{height: 1, left: nil, right: nil, value: {2, 20}},
                   value: {1, 10}
                 },
                 right: %{
                   height: 2,
                   left: %{height: 1, left: nil, right: nil, value: {7, 700}},
                   right: nil,
                   value: {9, 90}
                 },
                 value: {5, 50}
               },
               size: 5
             },
             tree
           )

    assert AVLTree.put_left(tree, {8, 80}) == AVLTree.put_right(tree, {8, 80})
    assert AVLTree.put_left(tree, {8, 80}) == AVLTree.put(tree, {8, 80})

    tree = AVLTree.put_left(tree, {7, 71})
    tree = AVLTree.put_left(tree, {7, 72})
    tree = AVLTree.put_left(tree, {7, 73})

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

    assert match?(
             %{
               root: %{
                 height: 4,
                 left: %{
                   height: 2,
                   left: nil,
                   right: %{height: 1, left: nil, right: nil, value: {2, 20}},
                   value: {1, 10}
                 },
                 right: %{
                   height: 3,
                   left: %{
                     height: 2,
                     left: %{height: 1, left: nil, right: nil, value: {7, 73}},
                     right: %{height: 1, left: nil, right: nil, value: {7, 71}},
                     value: {7, 72}
                   },
                   right: %{height: 1, left: nil, right: nil, value: {9, 90}},
                   value: {7, 700}
                 },
                 value: {5, 50}
               },
               size: 8
             },
             tree
           )

    tree = AVLTree.put_right(tree, {7, 74})
    tree = AVLTree.put_right(tree, {7, 75})
    tree = AVLTree.put_right(tree, {7, 76})

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

    assert match?(
             %{
               root: %{
                 height: 4,
                 left: %{
                   height: 3,
                   left: %{
                     height: 2,
                     left: nil,
                     right: %{height: 1, left: nil, right: nil, value: {2, 20}},
                     value: {1, 10}
                   },
                   right: %{
                     height: 2,
                     left: %{height: 1, left: nil, right: nil, value: {7, 73}},
                     right: %{height: 1, left: nil, right: nil, value: {7, 71}},
                     value: {7, 72}
                   },
                   value: {5, 50}
                 },
                 right: %{
                   height: 3,
                   left: %{height: 1, left: nil, right: nil, value: {7, 74}},
                   right: %{
                     height: 2,
                     left: %{height: 1, left: nil, right: nil, value: {7, 76}},
                     right: nil,
                     value: {9, 90}
                   },
                   value: {7, 75}
                 },
                 value: {7, 700}
               },
               size: 11
             },
             tree
           )
  end

  test "remove" do
    tree = Enum.into([5, 9, 3, 8, 1, 6, 7], AVLTree.new())
    assert match?({false, ^tree}, AVLTree.remove(tree, 4))
    {true, tree} = AVLTree.remove(tree, 3)

    assert match?(
             %{
               root: %{
                 height: 3,
                 left: %{
                   height: 2,
                   left: %{height: 1, left: nil, right: nil, value: 1},
                   right: nil,
                   value: 5
                 },
                 right: %{
                   height: 2,
                   left: %{height: 1, left: nil, right: nil, value: 7},
                   right: %{height: 1, left: nil, right: nil, value: 9},
                   value: 8
                 },
                 value: 6
               },
               size: 6
             },
             tree
           )

    assert Enum.to_list(tree) == [1, 5, 6, 7, 8, 9]

    {true, tree} = AVLTree.remove(tree, 1)

    assert match?(
             %{
               root: %{
                 height: 3,
                 left: %{height: 1, left: nil, right: nil, value: 5},
                 right: %{
                   height: 2,
                   left: %{height: 1, left: nil, right: nil, value: 7},
                   right: %{height: 1, left: nil, right: nil, value: 9},
                   value: 8
                 },
                 value: 6
               },
               size: 5
             },
             tree
           )

    assert Enum.to_list(tree) == [5, 6, 7, 8, 9]

    {true, tree} = AVLTree.remove(tree, 8)

    assert match?(
             %{
               root: %{
                 height: 3,
                 left: %{height: 1, left: nil, right: nil, value: 5},
                 right: %{
                   height: 2,
                   left: nil,
                   right: %{height: 1, left: nil, right: nil, value: 9},
                   value: 7
                 },
                 value: 6
               },
               size: 4
             },
             tree
           )

    assert Enum.to_list(tree) == [5, 6, 7, 9]

    tree = Enum.into([3, 1, 2, 4, 8, 0], tree)
    assert Enum.to_list(tree) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

    {true, tree1} = AVLTree.remove(tree, 6)
    assert Enum.to_list(tree1) == [0, 1, 2, 3, 4, 5, 7, 8, 9]

    tree = Enum.into([0, 3, 2, 1, 4, 8, 7, 9, 5, 6, 11, 12, 10, 14, 13, 15], AVLTree.new())
    {true, tree} = AVLTree.remove(tree, 4)
    assert Enum.to_list(tree) == [0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

    assert match?(
             %{
               root: %{
                 height: 5,
                 left: %{
                   height: 3,
                   left: %{
                     height: 2,
                     left: nil,
                     right: %{height: 1, left: nil, right: nil, value: 1},
                     value: 0
                   },
                   right: %{height: 1, left: nil, right: nil, value: 3},
                   value: 2
                 },
                 right: %{
                   height: 4,
                   left: %{
                     height: 3,
                     left: %{height: 1, left: nil, right: nil, value: 6},
                     right: %{
                       height: 2,
                       left: %{height: 1, left: nil, right: nil, value: 8},
                       right: %{height: 1, left: nil, right: nil, value: 10},
                       value: 9
                     },
                     value: 7
                   },
                   right: %{
                     height: 3,
                     left: %{height: 1, left: nil, right: nil, value: 12},
                     right: %{
                       height: 2,
                       left: nil,
                       right: %{height: 1, left: nil, right: nil, value: 15},
                       value: 14
                     },
                     value: 13
                   },
                   value: 11
                 },
                 value: 5
               },
               size: 15
             },
             tree
           )
  end
end
