
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