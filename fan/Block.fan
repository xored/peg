@Js
enum class RootRule : Rule {
  INSTANCE;  
  internal override Bool exec(Matcher matcher) { false }
}

@Js
class Block {
  const Rule rule
  const Int start
  Int? end
  Block? parent
  Block[] children
  
  new make(Rule rule, Int start, Block? parent := null) {
    children = Block[,]
    this.rule = rule
    this.start = start
    this.parent = parent
  }
  
  Range range() {
    start..<end
  }
  
  Int size() {
    end - start
  }
  
  override Bool equals(Obj? that) {
    Block? o := that as Block
    return null != o && start == o.start && end == o.end && rule == o.rule
  }
  
  override Int hash() {
    prime := 13
    result := 1
    result = prime * result + start.hash
    result = prime * result + end.hash
    result = prime * result + rule.hash
    return result;
  }
  
  override Int compare(Obj obj) {
    Block o := (Block)obj
    Int ret := 0
    if (start == o.start) {
      ret = o.size - size // reverse order (block with smaller size should go after block with greater size)
    } else {
      ret = start - o.start
    }
    return ret      
  }

  ** Converts a list of blocks into a tree. The blocks' parent and children fields
  ** are not taken into account (their old values will be overwritten).
  ** blocks list must not be empty.
  ** If length is -1, the first block in the list tretead as a root.
  ** If length > 0, a new block with start = 0, end = length and rule = RootRule is created
  ** as a root for the tree, and all the other blocks are made its children. 
  static Block toTree(Block[] blocks, Int length := -1) {
    Block[] t := [,]
    t.addAll(blocks)
    t.sort
    t = removeDuplicates(t)
    Block root := t.first
    Int kidStart := 1
    if (-1 < length) {
      root = Block(RootRule.INSTANCE, 0)
      root.end = length
      kidStart = 0
    }
    fillChildren(root, t, kidStart)
    return root
  }
  
  private static Block[] removeDuplicates(Block[] blocks) {
    Block[] ret := [,]
    for (Int i := 0; i < blocks.size; ++i) {
      if (0 == i || !blocks[i-1].equals(blocks[i])) {
        ret.add(blocks[i])
      }
    }
    return ret
  }
  
  private static Int fillChildren(Block parent, Block[] sortedBlocks, Int index) {
    parent.children.clear
    Int i := index    
    while (i < sortedBlocks.size && parent.end > sortedBlocks[i].start) {
      Block kid := sortedBlocks[i]
      kid.parent = parent
      i = fillChildren(kid, sortedBlocks, i+1)
      parent.children.add(kid)      
    }
    return i
  }  
}