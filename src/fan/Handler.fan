
** Handler represents a stack of visits of blocks with abilities
** to roll back to the previously pushed state.
@Js
mixin Handler {

  ** Called by parser to pass a grammar block to the handler.
  ** Passed block may be rolled back in future, so getting a block through this method
  ** does not always mean this block presents in input. 
  abstract Void visit(Block block)
  
  ** Signal to push the current state. 
  ** I.e. the handler should save its current state (including any blocks visited so far) into an internal stack and be able
  ** to roll back to it.
  abstract Void push()
  
  ** Signal to drop changes which are made after previous push.
  ** Handler should backtrack to the previously pushed state, i.e. drop any blocks visited after the previous push(). 
  abstract Void rollback()
  
  ** Signal to apply changes which are made after previous push.
  ** Previously pushed state should be applied, i.e. the parser is "sure" about this state, and  
  ** rollback() can't be called for it anymore.
  abstract Void apply()
}

** Handler, which stores blocks in a list.
@Js
class ListHandler : Handler
{
  ** Visited blocks. 
  Block[] blocks := [,] { private set }
  
  private Int[] sizes := [0]
  
  override Void push() { sizes.push(blocks.size) }
  
  override Void rollback() { blocks.removeRange(sizes.pop..<blocks.size) }
  
  override Void apply() { sizes.pop }
  
  override Void visit(Block block) { blocks.add(block) }
}

** Handler which does nothing. May be used to just check, if a text conforms to the grammar.
@Js
class NullHandler : Handler 
{
  override Void push() {}
  
  override Void rollback() {}
  
  override Void apply() {}
  
  override Void visit(Block block) {}
}