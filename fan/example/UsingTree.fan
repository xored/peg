
class UsingTree
{
  private static Void traverse(Grammar g, Block node, Str input) {
    n := g.name(node.rule)
    if ("Int" == n || "Real" == n) {
      echo("Number: ${input[node.range]}")      
    }
    node.children.each { traverse(g, it, input) }
  }
  
  static Void main() {
    grammarText := "Number <- ((Real / Int) ' '?)* !.\n" + 
      "Part <- [0-9]+\n" + 
      "Int <- Part\n" +
      "Real <- Part '.' Part";
    input := "75 33.23 11"
    
    g := Grammar.fromStr(grammarText)
    p := Parser(g.start)
    root := p.tree(input)
    traverse(g, root, input)    
  }
}
