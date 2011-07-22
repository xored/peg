
class ParserTest : Test
{
    
  Void testGrammarParsing() {
    generalTest("A <- .", ["DOT" : 5..<6])
    generalTest("A <- a")
    generalTest("A <- 'a'", ["Literal" : 5..<8])
    generalTest("A <- [a-z]", ["Class" : 5..<10])
    generalTest("A <- a b", ["Sequence" : 5..<8])
    generalTest("A <- a / b", ["SLASH" : 7..<9])
    generalTest("A <- a*", ["STAR" : 6..<7])
  }
  
  private Void generalTest(Str in, Str:Range blocks := [:], Grammar grammar := MetaGrammar()) {
    lh := ListHandler()
    p := Parser(grammar, lh).run(in.toBuf)
    verifyEq(p.match.state, MatchState.success)
    verifyEq(lh.blocks.last.name, grammar.start)
    blocks.each |r, n| {
      b := lh.blocks.find { it.name == n }
      verifyEq(b?.range, r)
    }
  }
  
}
