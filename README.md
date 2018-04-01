# AVL Tree

Pure Elixir [AVL tree](https://en.wikipedia.org/wiki/AVL_tree) implementation.

Features:
- custom comparison function
- `Collectable`, `Enumerable`, `Inspect`, `String.Chars` protocols
- human readable visualization

## Usage
### Default comparsion function (`a < b` - ascending order)
#### Inserting individual values
```elixir
tree = AVLTree.new()

tree = tree
  |> AVLTree.put(2)
  |> AVLTree.put(1)
  |> AVLTree.put(3)
# #AVLTree<size: 3, height: 2>

Enum.to_list(tree) # [1, 2, 3]
```
#### Inserting list of values
```elixir
tree = Enum.into([10, 8, 4, 6, 5, 7], tree) # #AVLTree<size: 9, height: 4>

Enum.to_list(tree) # [1, 2, 3, 4, 5, 6, 7, 8, 10]
```
#### Searching
```elixir
AVLTree.get(tree, 4) # 4
AVLTree.get(tree, 9) # nil

AVLTree.has_value(tree, 4) # true
AVLTree.has_value(tree, 9) # false

Enum.member?(tree, 4) # true
Enum.member?(tree, 9) # false
```
#### Removing
```elixir
{true, tree} = AVLTree.remove(tree, 8) # {true, #AVLTree<size: 8, height: 4>}
Enum.to_list(tree) # [1, 2, 3, 4, 5, 6, 7, 10]

{false, tree} = AVLTree.remove(tree, 9) # {false, #AVLTree<size: 8, height: 4>}
Enum.to_list(tree) # [1, 2, 3, 4, 5, 6, 7, 10]
```

#### Visualization
```elixir
IO.puts(to_string(tree))
```
output:
```
   3        
 ┌─┴───┐    
 2     6    
┌┴┐  ┌─┴─┐  
1    5   8  
    ┌┴┐ ┌┴─┐
    4   7 10
```
### Custom comparsion function
#### Inserting tuples, descending order by first field
```elixir
tree = AVLTree.new(fn {ka, _}, {kb, _} -> ka > kb end)
# #AVLTree<size: 0, height: 0>

tree = Enum.into([{2, "val 2"}, {3, "val 3"}, {1, "val 1"}], tree)
# #AVLTree<size: 3, height: 2>

Enum.to_list(tree) # [{3, "val 3"}, {2, "val 2"}, {1, "val 1"}]
```
#### Inserting values with duplicate key field
```elixir
tree = AVLTree.put_left(tree, {2, "val 2.1"})
#AVLTree<size: 4, height: 3>

Enum.to_list(tree)
# [{3, "val 3"}, {2, "val 2.1"}, {2, "val 2"}, {1, "val 1"}]

tree = AVLTree.put_right(tree, {2, "val 2.2"})
#AVLTree<size: 5, height: 3>

Enum.to_list(tree)                            
# [{3, "val 3"}, {2, "val 2.1"}, {2, "val 2"}, {2, "val 2.2"}, {1, "val 1"}]
```
