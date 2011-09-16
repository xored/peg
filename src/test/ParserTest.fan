
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
  
  Void testInfiniteLoop() {
    infiniteLoopTest("", "A <- (!.)*")
    infiniteLoopTest("aaa", "A <- (!'b')*")
    
    b := "A <- (B*)*
          B <- 'b'"
    infiniteLoopTest("", b)
    infiniteLoopTest("bbb", b)
    
    numbers := "Numbers <- Number*
                Number <- [0-9]+ / Spacing
                Spacing <- ' ' / '\t' / '\n' / EOF
                EOF <- !."     
    infiniteLoopTest("", numbers)
    infiniteLoopTest("0 20 3", numbers)
  }
  
  private Void infiniteLoopTest(Str in, Str grammar) {
    p := Parser(Grammar.fromStr(grammar), ListHandler()).run(in.toBuf)
    verifyEq(p.match.state, MatchState.fail)
    verify(p.match is InfiniteLoop)
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
  }
  
  Void testLack() {
    // lack+finished state in t
    lackTest("A <- 'aaaa'", ["aa", "aa"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.success, p.match.state)
      verifyEq(0..<4, lh.blocks.first?.range)
    }
    lackTest("A <- 'aaaa'", ["aa", "a"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.fail, p.match.state)
    }
    
    // lack+finished state in clazz
    lackTest("A <- [a-z]", ["", "a"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.success, p.match.state)
      verifyEq(0..<1, lh.blocks.first?.range)
    }
    lackTest("A <- [a-z]", ["", ""]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.fail, p.match.state)
    }
    
    // lack+finished state in choice
    lackTest("A <- 'aaa' / 'aab'", ["aa", "b"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.success, p.match.state)
      verifyEq(0..<3, lh.blocks.first?.range)
    }
    lackTest("A <- 'abb' / 'abd'", ["ab", "c"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.fail, p.match.state)
    }
    lackTest("A <- 'b' / 'aaa' / 'aab'", ["a", "a", "b"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.success, p.match.state)
      verifyEq(0..<3, lh.blocks.first?.range)
    }
    
    // lack+finished state in rep
    lackTest("A <- 'a'*", ["aa", "a"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.success, p.match.state)
      verifyEq(0..<3, lh.blocks.first?.range)
    }
    lackTest("A <- 'a'*", ["aa", "b"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.success, p.match.state)
      verifyEq(0..<2, lh.blocks.first?.range)
    }
    lackTest("A <- 'a'*", ["b", "a"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.success, p.match.state)
      verifyEq(0..<0, lh.blocks.first?.range)
    }
    lackTest("A <- 'aaa'*", ["a", "a"]) |Parser p, ListHandler lh| { 
      verifyEq(MatchState.success, p.match.state)
      verifyEq(0..<0, lh.blocks.first?.range)
    }
  }
  
  private Void lackTest(Str grammar, Str[] in, |Parser p, ListHandler lh| f) {
    g := Grammar.fromStr(grammar)
    t := in.join
    cur := 0
    lh := ListHandler()
    p := Parser(g, lh)
    in.each |s, i| { 
      buf := t.toBuf[0..<cur + s.size]
      cur += s.size
      p.run(buf, in.size-1 == i)
    }
    f(p, lh)
  }
  
  Void testUnicode() {
    wholeTest("A<-'текст'", ["Literal" : 3..<10])
    multiTest("A<-'текст'", ["Literal" : 3..<10])
    
    root := Parser.tree(Grammar.fromStr("A <- '(+)' / '№'"), "№".toBuf)
    verifyEq(root.block.name, "A")
    verifyEq(root.block.range, 0..<1)
  }
  
  Void testTree() {
    grammarText := 
      "Number <- ((Real / Int) ' '?)* EOF 
       Part <- [0-9]+ 
       Int <- Part
       Real <- Part '.' Part
       EOF <- !."
    input := "75 33.23 11"
    
    root := Parser.tree(Grammar.fromStr(grammarText), input.toBuf)
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
  
  Void testRep() {
    grammarText := 
      "A <- (B* C D)+ BA
       B <- 'b'
       C <- 'c'
       D <- (![\\n] .)* [\\n]+
       BA <- 'ba'"
    input := "c
              ba"
    lh := ListHandler()
    p := Parser(Grammar.fromStr(grammarText), lh).run(input.toBuf)
    // ensure that the last 'b' is not parsed as B
    verifyEq(lh.blocks, 
      Block[BlockImpl("C", 0..<1), BlockImpl("D", 1..<2), BlockImpl("BA", 2..<4), BlockImpl("A", 0..<4)])
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
