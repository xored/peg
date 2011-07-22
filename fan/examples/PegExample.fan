
class PegExample
{
  static Void main(Str[] args) {
    lh := ListHandler()
    p := Parser(MetaGrammar(), lh)
    in := "A <- !a" // TODO: this fails
    p.run(in.toBuf, true)
    echo("Result is $p.match")
    echo("Blocks: " + lh.blocks)
    echo("Stack:")
    p.expressionStack.eachr { echo(it) }
  }
}
