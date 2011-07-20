
** Converts blocks into the block tree.
@Js
internal class TreeHandler : Handler
{
  
  private Block[] blocks := [,]
  private Int[] sizes := [0]
  
  override Void push() { sizes.push(blocks.size) }
  
  override Void rollback() { blocks.size = sizes.pop }
  
  override Void apply() { sizes.pop }
  
  override Void visit(Block block) { blocks.add(block) }
  
  ** Returns a block tree.
  BlockNode? finish() {
    if (blocks.isEmpty) {
      return null
    }
    root := BlockNodeImpl(blocks.last)
    if (2 <= blocks.size) {
      traverse(blocks.size - 2, root)      
    }
    return root
  }
  
  private Int traverse(Int index, BlockNode parent) {
    n := BlockNodeImpl(blocks[index])
    parent.kids.add(n)
    --index
    while (0 > index) {
      kid := blocks[index]
      if (kid.range.start < n.block.range.start || kid.range.end > n.block.range.end) {
        // not my child
        break
      }
      index = traverse(index, n)      
    }
    return index
  }
  
}

@Js
internal class BlockNodeImpl : BlockNode 
{  
  override Block block { private set }
  
  override BlockNode[] kids := [,] { private set }
  
  new make(Block block) {
    this.block = block
  }  
}
