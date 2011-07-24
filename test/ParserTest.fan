
class ParserTest : Test
{
    
  Void testGrammarParsing() {
    // base expressions
    wholeTest("A <- .", ["DOT" : 5..<6])
    wholeTest("A <- a")
    wholeTest("A <- 'a'", ["Literal" : 5..<8])
    wholeTest("A <- [a-z]", ["Class" : 5..<10])
    wholeTest("A <- a b", ["Sequence" : 5..<8])
    wholeTest("A <- a / b", ["SLASH" : 7..<9])
    wholeTest("A <- a*", ["STAR" : 6..<7])
    wholeTest("A <- !a", ["NOT" : 5..<6])
    wholeTest("A <- &a", ["AND" : 5..<6])
    wholeTest("A <- a #comment\n", ["Comment" : 7..<16]) // comment must end with EOLN
  }
  
  Void testMultiRun() {
    // base expressions in multiple chunks
    multiTest("A <- .", ["DOT" : 5..<6])
    multiTest("A <- a")
    multiTest("A <- 'a'", ["Literal" : 5..<8])
    multiTest("A <- [a-z]", ["Class" : 5..<10])
    multiTest("A <- a b", ["Sequence" : 5..<8])
    multiTest("A <- a / b", ["SLASH" : 7..<9])
    multiTest("A <- a*", ["STAR" : 6..<7])
    multiTest("A <- !a", ["NOT" : 5..<6])
    multiTest("A <- &a", ["AND" : 5..<6])
    multiTest("A <- a #comment\n", ["Comment" : 7..<16]) // comment must end with EOLN
  }
  
  private Void wholeTest(Str in, Str:Range blocks := [:], Grammar grammar := MetaGrammar()) {
    p := Parser(grammar, ListHandler()).run(in.toBuf)
    runResultsTest(p, blocks, grammar)
  }
  
  private Void multiTest(Str in, Str:Range blocks := [:], Grammar grammar := MetaGrammar()) {
    whole := in.toBuf
    first := whole[0..2]
    second := whole[0..5]
    p := Parser(grammar, ListHandler())
    p.run(first, false)
    p.run(second, false)
    p.run(whole, true)
    runResultsTest(p, blocks, grammar)
  }
  
  private Void runResultsTest(Parser p, Str:Range blocks := [:], Grammar grammar := MetaGrammar()) {
    verifyEq(p.match.state, MatchState.success)
    lh := p.handler as ListHandler
    verifyEq(lh.blocks.last.name, grammar.start)
    blocks.each |r, n| {
      b := lh.blocks.find { it.name == n }
      verifyEq(b?.range, r)
    }
  }
  
}
