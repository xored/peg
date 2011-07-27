
class PegExample
{
  static Void main(Str[] args) {
    grammarText := 
      "Number <- ((Real / Int) ' '?)* EOF 
       Part <- [0-9]+ 
       Int <- Part
       Real <- Part '.' Part
       EOF <- !."
    input := "75 33.23 11"
    
    root := Parser.tree(grammarText, input.toBuf)
    traverse(root, input, 0)
  }
  
  private static Void traverse(BlockNode node, Str input, Int indent) {
    sb := StrBuf()
    indent.times { sb.add(" ") }
    sb.add("Type: ")
    sb.add(node.block.name)
    sb.add(", content: ")
    sb.add(input[node.block.range])
    echo(sb)
    node.kids.each { traverse(it, input, indent+1) }
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