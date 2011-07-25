
class PegExample
{
  static Void main(Str[] args) {
    parseGrammar("A <- !B
                  B <- 'b' / 'c'")
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
    skip := Str:Str ["EndOfLine":"", "Space":"", "Comment":"", "Spacing":"", "IdentStart":"", "IdentCont":""]
    blocks.each {
      if (null == skip[it.name]) {
        ret.add(it)
      }
    }
    return ret
  }
}