
** Block is a part of input which is parsed by some rule.
@Js
const mixin Block 
{
  ** The rule which parsed this block (non-terminal). Never empty.
  abstract Str name()
  
  ** Range of input which occupied by this block. May be empty.
  abstract Range range()
  
  override Bool equals(Obj? other) {
    o := other as Block
    return null != o && name == o.name && range == o.range
  }
  
  override Int hash() { 
    prime := 31
    r := 1
    r = r * prime + name.hash
    r = r * prime + range.hash
    return r
  }
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

** General implementation of block interface.
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

** General implementation of BlockNode. 
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

  override Str toStr() {
    sb := StrBuf()
    print(this, sb, 0)
    return sb.toStr
  }
  
  private static Void print(BlockNode node, StrBuf sb, Int indent) {
    indent.times { sb.add("  ") }
    sb.add(node.block)
    sb.add(", kids: ")
    sb.add(node.kids.size)
    sb.add("\n")
    node.kids.each { print(it, sb, indent + 1) }
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
    pr := parent.block.range
    while (0 <= i) {
      t := blocks[i]
      cmin := pr.start <= t.range.start && t.range.start <= pr.end      
      cmax := pr.start <= t.range.end && t.range.end <= pr.end 
      if (cmin && cmax) {
        kids.add(BlockNodeImpl {
          block = t
          it.parent = parent
          tk := BlockNode[,]
          i = fillKids(it, blocks, i-1, tk)
          it.kids = tk.reverse
        })
      } else {
        break
      }
    }
    return i    
  }
}