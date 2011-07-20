
** Handler for parsing expression grammar.
** Uses non-terminals from the meta grammar published in the original paper
** (http://pdos.csail.mit.edu/~baford/packrat/popl04/).
@Js
internal class MetaHandler : Handler
{
  private Block[] blocks := [,]
  private Int[] sizes := [0]
  
  override Void push() { sizes.push(blocks.size) }
  
  override Void rollback() { blocks.size = sizes.pop }
  
  override Void apply() { sizes.pop }
  
  override Void visit(Block block) { blocks.add(block) }
  
  private Str:Expression rules := [:]
  private Expression? start := null 

  ** Builds grammar from previously collected blocks.
  Grammar finish(Str text) {
    rules = [:]
    start = null
    restoreGrammar(text)
    return GrammarImpl(rules, start)
  }
  
  private Void restoreGrammar(Str text) {
    if ("Grammar" != blocks.last.name) {
      throw ArgErr("Expected 'Grammar' as a top rule, but got '$blocks.last.name'")
    }
  }
  
}

@Js
internal const class GrammarImpl : Grammar 
{
  override const Str:Expression rules
  
  override const Expression start
  
  new make(Str:Expression rules, Expression start) {
    this.rules = rules
    this.start = start
  }  
}