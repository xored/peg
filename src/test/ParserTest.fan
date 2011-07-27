
class ParserTest : Test
{
    
  Void testGrammarParsing() {
    // base expressions
    wholeTest("A <- .", ["DOT" : 5..<6])
    wholeTest("A <- a")
    wholeTest("A <- 'a'", ["Literal" : 5..<8])
    wholeTest("A <- '\\n'", ["Char" : 6..<8])
    wholeTest("A <- \"\\n\"", ["Char" : 6..<8])
    wholeTest("A <- \"a\"", ["Literal" : 5..<8])
    wholeTest("A <- [a-z]", ["Class" : 5..<10])
    wholeTest("A <- a b", ["Sequence" : 5..<8])
    wholeTest("A <- a / b", ["SLASH" : 7..<8])
    wholeTest("A <- a*", ["STAR" : 6..<7])
    wholeTest("A <- !a", ["NOT" : 5..<6])
    wholeTest("A <- &a", ["AND" : 5..<6])
    wholeTest("A <- a #comment\n", ["Comment" : 7..<16]) // comment must end with EOLN
    wholeTest("A <- !. #comment\n", ["Comment" : 8..<17])
    wholeTest("# Comment
               
               A <- !.")
  }
  
  Void testMultiRun() {
    // base expressions in multiple chunks
    multiTest("A <- .", ["DOT" : 5..<6])
    multiTest("A <- a")
    multiTest("A <- 'a'", ["Literal" : 5..<8])
    multiTest("A <- \"a\"", ["Literal" : 5..<8])
    multiTest("A <- '\\n'", ["Char" : 6..<8])
    multiTest("A <- \"\\n\"", ["Char" : 6..<8])
    multiTest("A <- [a-z]", ["Class" : 5..<10])
    multiTest("A <- a b", ["Sequence" : 5..<8])
    multiTest("A <- a / b", ["SLASH" : 7..<8])
    multiTest("A <- a*", ["STAR" : 6..<7])
    multiTest("A <- !a", ["NOT" : 5..<6])
    multiTest("A <- &a", ["AND" : 5..<6])
    multiTest("A <- a #comment\n", ["Comment" : 7..<16]) // comment must end with EOLN
    multiTest("A <- !. #comment\n", ["Comment" : 8..<17])
    multiTest("# Comment
               
               A <- !.")
    
    // TODO: need tests for special cases (when "lack" + "finished" state are
    // handled specially in Parser, e.g. t(), choice(), rep(), etc)
  }
  
  Void testUnicode() {
    wholeTest("A<-'текст'", ["Literal" : 3..<10])
    multiTest("A<-'текст'", ["Literal" : 3..<10])
  }
  
  Void testTree() {
    grammarText := 
      "Number <- ((Real / Int) ' '?)* EOF 
       Part <- [0-9]+ 
       Int <- Part
       Real <- Part '.' Part
       EOF <- !."
    input := "75 33.23 11"
    
    root := Parser.tree(grammarText, input.toBuf)
    ints := Str[,]
    reals := Str[,]
    traverse(root) |Block b| {
      if ("Int" == b.name) {
        ints.add(input[b.range])
      }
      if ("Real" == b.name) {
        reals.add(input[b.range])
      }
    }
    verifyEq(ints, ["75", "11"])
    verifyEq(reals, ["33.23"])
  }
  
  private Void wholeTest(Str in, Str:Range blocks := [:], Grammar grammar := MetaGrammar.val) {
    p := Parser(grammar, ListHandler()).run(in.toBuf)
    runResultsTest(p, blocks, grammar)
  }
  
  private Void multiTest(Str in, Str:Range blocks := [:], Grammar grammar := MetaGrammar.val) {
    whole := in.toBuf
    first := whole[0..2]
    second := whole[0..5]
    p := Parser(grammar, ListHandler())
    p.run(first, false)
    p.run(second, false)
    p.run(whole, true)
    runResultsTest(p, blocks, grammar)
  }
  
  private Void runResultsTest(Parser p, Str:Range blocks := [:], Grammar grammar := MetaGrammar.val) {
    verifyEq(p.match.state, MatchState.success)
    lh := p.handler as ListHandler
    verifyEq(lh.blocks.last.name, grammar.start)
    blocks.each |r, n| {
      b := lh.blocks.find { it.name == n }
      verifyEq(b?.range, r)
    }
  }
  
  private static Void traverse(BlockNode node, |Block| f) {
    f(node.block)
    node.kids.each { traverse(it, f) }
  }
  
}
