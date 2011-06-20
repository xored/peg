
internal class SimpleHandler : Handler {
  private Grammar g
  private Str input
  private Int[] sizes := [0,]
  
  Decimal[] numbers := [,]
  
  new make(Grammar g, Str input) {
    this.g = g
    this.input = input
  }
  
  override Void visit(Block block) {
    n := g.name(block.rule)
    if ("Int" == n || "Real" == n) {
      numbers.add(Decimal.fromStr(input[block.range]))
    }
  }
  
  override Void push() {
    sizes.push(numbers.size)
  }
  
  override Void pop(Bool drop) {
    Int s := sizes.pop
    if (!drop) {
      numbers.size = s      
    }
  }
}

class UsingHandler
{
  static Void main(Str[] args) {
    grammarText := "Number <- ((Real / Int) ' '?)* !.\n" + 
      "Part <- [0-9]+\n" + 
      "Int <- Part\n" +
      "Real <- Part '.' Part";
    input := "75 33.23 11"
    
    g := Grammar.fromStr(grammarText)
    p := Parser(g.start)
    sh := SimpleHandler(g, input)
    p.parse(input.toBuf, sh)
    sh.numbers.each { echo("Found number: $it") }
  }
}
