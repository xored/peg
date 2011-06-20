
@Js
internal class BlockBuilder : StrMatcher {  
  Block? root := null { private set }
  private Block[] parent := Block[,]  
  
  new make(Str content, Grammar[] gs) : super(content, gs) {}
  
  override Bool match(Rule rule) {
    block := Block(rule, this.cursor, parent.peek)
    if (rule is RuleContainer) {
      parent.push(block)
    }
    cursor := this.cursor
    retVal := rule.exec(this)
    if (retVal) {
      if (block.parent != null) {
          if (rule is LazyRule) {
            block.parent.children.add(block.children[0])
          } else {          
            block.parent.children.add(block)
          }
      }
      block.end = this.cursor
    } else {
      this.cursor = cursor
    }
    if (rule is RuleContainer) {
      root = parent.pop
      if (root.end == null) root = null
    }
    return retVal
  }
}
