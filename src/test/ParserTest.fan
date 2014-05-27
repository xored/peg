
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
    verifyType(p.match, InfiniteLoop#)
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
    
    grammar := 
      "Top <- F M+ B !.
       F <- 'function '
       M <- (!B !' ' .)+ ' '
       B <- 'b'"
    input := "function âmemsetâ /âmemsetâ b"
    root = Parser.tree(Grammar.fromStr(grammar), input.toBuf)
    verifyEq(root.kids[2].block.name, "M")
    verifyEq(root.kids[2].block.range, 18..<28)
    verifyEq(root.kids[2].block.byteRange, 20..<32)
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
      Block[block("C", 0..<1), block("D", 1..<2), block("BA", 2..<4), block("A", 0..<4)])
  }
  
  Void testLazyRep() {
    //the same as testRep(), but checks lazy repetition accuracy
    grammarText := 
      "A <- (B* C D)+ BA
       B <- 'b'
       C <- 'c'
       D <- (![\\n] .)* [\\n]+
       BA <- 'ba'"
    input := "c
              ba"
    
    grammarText2 := 
      "A <- (B* C D)+ BA
       B <- 'b'
       C <- 'c'
       D <- .*? [\\n]+
       BA <- 'ba'"
    lh := ListHandler()
    lh2 := ListHandler()
    p := Parser(Grammar.fromStr(grammarText), lh).run(input.toBuf)
    p2 := Parser(Grammar.fromStr(grammarText2), lh2).run(input.toBuf)
    verifyEq(lh.blocks, lh2.blocks)
    
    //if there is no expression after lazy-rep operator then it throws ParseErr exception 
    grammarText = "A <- 'a'*?"
    input = "a"
    lh = ListHandler()
    verifyErr(ParseErr#) { Parser(Grammar.fromStr(grammarText), lh).run(input.toBuf)}
    
    //space between * and ? must throw parse error 
    grammarText = 
          "A <- B   * ?   C
           B <- 'b'
           C <- 'c'"
    input = "bbbbc"
    lh = ListHandler()
    verifyErr(ParseErr#) { Parser(Grammar.fromStr(grammarText), lh).run(input.toBuf)}
    
    grammarText = 
          "A  <- B   *? BC  *? D  *?  DE     
           B  <- 'b'
           BC <- 'bc'
           D  <- 'd'
           DE  <- 'de'"
    input = "bbbbcbcdde"
    lh = ListHandler()
    p = Parser(Grammar.fromStr(grammarText), lh).run(input.toBuf)
    verifyEq(lh.blocks, Block[block("B",0..<1),block("B",1..<2), block("B", 2..<3), 
      block("BC",3..<5), block("BC",5..<7), block("D", 7..<8), block("DE",8..<10), block("A", 0..<10)])
    
    //Check tree structure
    grammarText = 
          "A   <- P* EOF
           P   <- 'function' S [a-z]+ '(' ')' '{' B
           S   <- ' ' / '\t' / '\n'
           B   <- (C / .)*? '}'
           C   <- '/*' .*? '*/'          
           EOF <- !."
    input = "function aaaa(){ 
                  /* comment zzzzzz */
                  print('hello world')    
                  }function bbbb(){ /**/ /* **** */ }"
    
    root := Parser.tree(Grammar.fromStr(grammarText), input.toBuf)
    //verify 
    //A -> P -> S
    //       -> B -> C
    //  -> P -> S
    //       -> B -> C
    //            -> C
    blockC1 := root.kids[0].kids[1].kids[0].block
    blockC2 := root.kids[1].kids[1].kids[0].block
    blockC3 := root.kids[1].kids[1].kids[1].block
    verifyEq(blockC1.name, "C")
    verifyEq(blockC2.name, "C")
    verifyEq(blockC3.name, "C")    
  }
  
  private static Block block(Str name, Range range, Range byteRange := range) { BlockImpl(name, range, byteRange) }
  
  Void testNotFound() {
    grammarText := 
      "A <- B / C
       C <- 'c'"
    input := "c"
    
    lh := ListHandler()
    p := Parser(Grammar.fromStr(grammarText), lh).run(input.toBuf)
    verifyType(p.match, NotFound#)    
    
    grammarText = "A <- B? 'a'"
    input = "a"
    p = Parser(Grammar.fromStr(grammarText), lh).run(input.toBuf)
    verifyType(p.match, NotFound#)
    
    grammarText = "A <- B? 'aa'"
    input = "aa"
    p = Parser(Grammar.fromStr(grammarText), lh).run(input.toBuf[0..<1], false)
    verifyType(p.match, NotFound#)
    p.run(input.toBuf[1..<2], true)
    verifyType(p.match, NotFound#)
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
  
  Void testNamespace(){
    //verify that after symbol '@' must be identifier
    verifyErr(ParseErr#) { Parser(Grammar.fromStr("@ A <- ."), ListHandler()).run("a".toBuf) }
    
    grammarText := 
         "@Z
          Number <- ((Real / Int) ' '?)* Utils:EOF
          Int <- Tokens:Part
          Real <- Tokens:Part '.' Tokens:Part"
    
    tokensGrammarText := "@Tokens Part <- [0-9]+"    
    utilsGrammarText := "@Utils EOF <- !."
    
    input := "75 33.23 11"
    
    grammar := Grammar.fromStr(grammarText)
    tokensGrammar := Grammar.fromStr(tokensGrammarText)
    utilsGrammar := Grammar.fromStr(utilsGrammarText)
    
    //check grammar dependencies
    verifyEq(((GrammarImpl)grammar).dependencies, ["Tokens", "Utils"])
    
    //verify that the parser match is type of NotFound if the grammar dependencies is not found
    lh:= ListHandler()    
    p:= Parser(grammar, lh).run(input.toBuf)
    verifyType(p.match, NotFound#)
    
    //
    multiGrammar := getMultiGrammar(grammar, [tokensGrammar, utilsGrammar])
    root := Parser.tree(multiGrammar, input.toBuf)
    
    ints := Str[,]
    reals := Str[,]
    tokens := Str[,]
    traverse(root) |Block b| {
      if ("Z:Int" == b.name) {
        ints.add(input[b.range])
      }
      if ("Z:Real" == b.name) {
        reals.add(input[b.range])
      }
      if("Tokens:Part" == b.name){
        tokens.add(input[b.range])
      }
    }
    verifyEq(ints, ["75", "11"])
    verifyEq(reals, ["33.23"])    
    verifyEq(tokens, ["75","33", "23", "11"])
    
  }
  
  ** Builds MutltiGrammar instance
  private static Grammar getMultiGrammar(GrammarImpl base, GrammarImpl [] deps) {
    ret := Grammar[,]
    ret.add(base)
    
    usedNs := Str[,]
    usedNs.add(base.namespace)
    
    namespaces := Str[,]
    base.dependencies.each 
    {
      if(!usedNs.contains(it))
        namespaces.push(it)
    }
    
    while(!namespaces.isEmpty){
      depNs := namespaces.removeAt(0)
      depGrammar := deps.find { it.namespace==depNs }
      if(depGrammar==null)
        throw ArgErr("Dependency grammar not found: $depNs")
      
      if (usedNs.contains(depGrammar.namespace)) {
        continue;
      }
      
      ret.add(depGrammar);
      usedNs.add(depGrammar.namespace);
      depGrammar.dependencies.each { if (!usedNs.contains(it)) {
          namespaces.push(it);
        }
      }
    }
    return MultiGrammar(base.start, ret);
  }  
}
