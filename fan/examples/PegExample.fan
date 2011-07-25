
class PegExample
{
  static Void main(Str[] args) {
    grammarText := 
      "Number <- ((Real / Int) ' '?)* !. 
       Part <- [0-9]+ 
       Int <- Part
       Real <- Part '.' Part"
    input := "75 33.23 11"
    
    root := Parser.parseAsTree(grammarText, input.toBuf)
    traverse(root, input)
  }
  
  private static Void traverse(BlockNode node, Str input) {
    n := node.block.name
    if ("Int" == n || "Real" == n) {
      echo("Number: ${input[node.block.range]}, type: $n")      
    }
    node.kids.each { traverse(it, input) }
  }
  
  private static Void parseGrammar(Str in) {
    lh := ListHandler()
    p := Parser(MetaGrammar(), lh)
    p.run(in.toBuf, true)
    if (MatchState.success == p.match.state) {
      grammar := GrammarBuilder.run(in, lh.blocks)
      echo(grammar)
    } else {
      echo("Result is $p.match")
      echo("Blocks: " + skipUnused(lh.blocks))
      echo("Stack:")
      p.expressionStack.eachr { echo(it) }
    }
  }
  
  private static Void parse(Str in) {
    lh := ListHandler()
    p := Parser(MetaGrammar(), lh)
    p.run(in.toBuf, true)
    echo("Result is $p.match")
    echo("Blocks: " + skipUnused(lh.blocks))
    echo("Stack:")
    p.expressionStack.eachr { echo(it) }
  }
  
  private static Block[] skipUnused(Block[] blocks) {
    ret := Block[,]
    skip := Str:Str[:] //["EndOfLine":"", "Space":"", "Comment":"", "Spacing":"", "IdentStart":"", "IdentCont":""]
    blocks.each {
      if (null == skip[it.name]) {
        ret.add(it)
      }
    }
    return ret
  }
}