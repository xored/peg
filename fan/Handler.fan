
** Handler represents a stack of visits of blocks with abilities
** to rollback to the prevoiusly pushed state.
@Js
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

** Simple handler, which stores all blocks in a list
@Js
class ListHandler : Handler
{
  Block[] blocks := [,] { private set }
  private Int[] sizes := [0]
  
  override Void push() { sizes.push(blocks.size) }
  
  override Void rollback() { blocks.size = sizes.pop }
  
  override Void apply() { sizes.pop }
  
  override Void visit(Block block) { blocks.add(block) }
}

** handler which does nothing. May be used to just check, if a text conforms to the grammar.
@Js
class NullHandler : Handler 
{
  override Void push() {}
  
  override Void rollback() {}
  
  override Void apply() {}
  
  override Void visit(Block block) {}
}