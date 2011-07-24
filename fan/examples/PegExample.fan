
class PegExample
{
  static Void main(Str[] args) {
    parse("A <- [a-bc]")
    parse("A <- \"abc\"")
    parse("A <- !a &b")
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
    skip := Str:Str ["EndOfLine":"", "Space":"", "Comment":"", "Spacing":"", "IdentStart":"", "IdentCont":"", "Char":""]
    blocks.each {
      if (null == skip[it.name]) {
        ret.add(it)
      }
    }
    return ret
  }
}