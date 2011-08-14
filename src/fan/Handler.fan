
** Handler represents a stack of visits of blocks with abilities
** to rollback to the prevoiusly pushed state.
mixin Handler {
  
  abstract Void visit(Block block)
  
  ** Signal to push the current state. 
  ** I.e. the handler should save its current state into an internal stack and be able
  ** to rollback to it.
  abstract Void push()
  
  ** Signal to drop changes which are made after previous push.
  ** handler should backtrack to the previously pushed state. 
  abstract Void rollback()
  
  ** Signal to apply changes which are made after previous push.
  ** Previously pushed state should be applied, i.e. the parser is "sure" about this state, and  
  ** rollback can't be called for it anymore.
  abstract Void apply()
}

** Handler, which stores blocks in a list.
class ListHandler : Handler
{
  Block[] blocks := [,] { private set }  
  private Int[] sizes := [0]
  
  override Void push() { sizes.push(blocks.size) }
  
  override Void rollback() { blocks.removeRange(sizes.pop..<blocks.size) }
  
  override Void apply() { sizes.pop }
  
  override Void visit(Block block) { blocks.add(block) }
}

** Handler which does nothing. May be used to just check, if a text conforms to the grammar.
class NullHandler : Handler 
{
  override Void push() {}
  
  override Void rollback() {}
  
  override Void apply() {}
  
  override Void visit(Block block) {}
}