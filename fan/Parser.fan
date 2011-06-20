
@Js
class Parser
{
  private Rule rule
  private Grammar[] grammars
  
  new make(Rule rule, Grammar[] grammars := [,]) {
    this.rule = rule
    this.grammars = grammars
  }
  
  Bool parse(Buf input, Handler handler) {
    m := BufMatcher(input, handler, grammars)
    return m.match(rule)
  }
  
  Block? tree(Str input) {
    builder := BlockBuilder(input, grammars)
    builder.match(rule)
    return builder.root
  }
}

@Js
mixin Handler {
  abstract Void visit(Block block)
  
  ** Signal to push the current state. 
  ** I.e. the handler should save its current state into an internal stack and be able
  ** to rollback to it.
  abstract Void push()
  
  ** Pop state signal.
  ** If drop is false, the state should be applied, so the handler should restore previously
  ** saved state. Otherwise, the state is just dropped. It means the state
  ** won't be used anymore, and the handler can free resources associated with this state.
  abstract Void pop(Bool drop)
}