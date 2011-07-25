
** Block is a part of input which is parsed by some rule.
@Js
const mixin Block 
{
  ** The rule which parsed this block (non-terminal). Never empty.
  abstract Str name()
  
  ** Range of input which occupied by this block. May be empty.
  abstract Range range()
}

** Generic implementation of block interface.
@Js
internal const class BlockImpl : Block
{
  override const Str name
  override const Range range
  
  new make(Str name, Range range) {
    if (name.isEmpty) {
      throw ArgErr("Block's name can't be empty")
    }
    this.name = name
    this.range = range
  }
  
  override Str toStr() { "BlockImpl($name, $range)" }
}

** A node in tree of blocks.
@Js
const mixin BlockNode
{
  ** This block 
  abstract Block block()
  
  ** Parent node (null for root)
  abstract BlockNode? parent()
  
  ** Kids
  abstract BlockNode[] kids()
}

** Generic implementation of BlockNode. 
@Js
internal const class BlockNodeImpl : BlockNode 
{
  override const Block block
  override const BlockNode? parent
  override const BlockNode[] kids
  
  new make(|This|? f := null) {
    if (null != f) {
      f(this)
    }
  }

  ** Constructs BlockNode tree from the given block list.
  static BlockNode fromList(Block[] blocks) {
    if (blocks.isEmpty) {
      throw ArgErr("Can't create block tree from empty list")
    }
    return BlockNodeImpl {
      block = blocks.last
      parent = null
      tk := BlockNode[,]
      fillKids(it, blocks, blocks.size - 2, tk)
      kids = tk.reverse
    }
  }
  
  private static Int fillKids(BlockNode parent, Block[] blocks, Int index, BlockNode[] kids) {
    i := index
    while (0 <= i) {
      t := blocks[i]
      cmin := parent.block.range.contains(t.range.min)
      cmax := parent.block.range.contains(t.range.max)
      if (cmin && cmax) {
        kids.add(BlockNodeImpl {
          block = t
          it.parent = parent
          tk := BlockNode[,]
          i = fillKids(it, blocks, i-1, tk)
          it.kids = tk.reverse
        })
      } else if (!cmin && !cmax) {
        break
      } else {
        // cmin != cmax
        throw ArgErr("Blocks $t and $parent.block intersect")
      }
    }
    return i    
  }
}