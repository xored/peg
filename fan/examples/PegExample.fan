
class PegExample
{
  static Void main(Str[] args) {
    lh := ListHandler()
    p := Parser(MetaGrammar(), lh)
    in := "A <- a #comment\n"
    wholeBuf := in.toBuf
    subBuf := wholeBuf[0..2]
    p.run(subBuf, false)
    p.run(wholeBuf, false)
    p.run(wholeBuf, true)
    echo("Result is $p.match")
    echo("Blocks: " + lh.blocks)
    echo("Stack:")
    p.expressionStack.eachr { echo(it) }
  }
}