
using peg

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
    
    root := Parser.tree(Grammar.fromStr(grammarText), input.toBuf)
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
}