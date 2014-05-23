
** Builds Grammar instance from the given blocks list.
** Blocks in the list must be in specific order described by MetaGrammar.
** 
** This class is considered a low-level API and made public for special purposes only. 
** Please, avoid using it, if possible. It may change in future without backward compatibility.  
@Js
class GrammarBuilder
{
  
  ** Constructs Grammar from the given blocks and the grammar's text.
  static Grammar run(Str text, Block[] blocks) { GrammarBuilder(text, blocks).grammar }

  private const Str text
  private Block[] blocks0
  private Int curInd
  private Str:Expression rules := [:]
  private Str lastNt := ""
  
  private new make(Str text, Block[] blocks) {
    this.text = text
    this.blocks0 = skipUnused(blocks)
    this.curInd = blocks0.size-1
  }
  
  private static Block[] skipUnused(Block[] blocks) {
    ret := Block[,]
    skip := Str:Str ["EndOfLine":"", "Space":"", "Comment":"", "Spacing":"", "IdentStart":"", "IdentCont":""]
    blocks.each {
      if (null == skip[it.name]) {
        ret.add(it)
      }
    }
    return ret
  }
  
  private Void check(Str name) {
    b := peek
    if (null == b) {
      throw ArgErr("Expected $name block, but run out of blocks")
    }
    if (name != b.name) {
      throw ArgErr("Expected $name block at $curInd index, but got $b.name")
    }
  }
  
  private Block pop(Str name) {
    check(name)
    return blocks0[curInd--]
  }
  
  private Block? popIf(Str name) {
    if (name == blocks0[curInd].name) {
      return blocks0[curInd--]
    } else {
      return null
    }
  }
  
  private Block? peek() { 0 <= curInd ? blocks0[curInd] : null }
  
  private Grammar grammar() {
    pop("Grammar")
    return eof
  }
  
  private Grammar eof() {
    pop("EndOfFile")
    while (0 <= curInd) {
      definition
    }
    if (lastNt.isEmpty) {
      throw ArgErr("No rules found. Grammar can't be empty.")
    }
    return GrammarImpl(lastNt, rules)
  }
  
  private Void definition() {
    pop("Definition")
    e := expression
    pop("LEFTARROW")
    lastNt = identifier
    rules[lastNt] = e
  }
  
  private Str identifier() { text[pop("Identifier").range].trim }
  
  private Expression expression() {
    pop("Expression")
    elist := Expression[,]
    elist.add(sequence)
    while (null != popIf("SLASH")) {
      elist.insert(0, sequence)
    }
    return 1 == elist.size ? elist.first : E.choice(elist)
  }
  
  private Expression sequence() {
    pop("Sequence")
    elist := Expression[,]
    while ("Prefix" == peek.name) {
      elist.add(prefix)
    }
    if (elist.isEmpty) {
      elist.add(E.empty)
    }
    return 1 == elist.size ? elist.first : E.seq(elist.reverse) 
  }
  
  private Expression prefix() {
    pop("Prefix")
    e := suffix
    if (null != popIf("NOT")) {
      e = E.not(e)
    } else if (null != popIf("AND")) {
      e = E.and(e)
    }
    return e
  }
  
  private Expression suffix() {
    pop("Suffix")
    Expression? e := null
    if (null != popIf("QUESTION")) {
      e = E.opt(primary)
    } else if (null != popIf("STAR")) {
      e = E.rep(primary)
    } else if (null != popIf("PLUS")) {
      e = E.rep1(primary)
    } else if(null != popIf("LazyRepetition") ) {
      e2 := prefix
      pop("QUESTION")
      pop("STAR")
      e = E.lazyRep(primary, e2)
    } else {
      e = primary
    }
    return e
  }
  
  private Expression primary() {
    pop("Primary")
    n := peek.name
    Expression? e := null
    switch(n) {
    case "Identifier":
      e = nt
      
    case "CLOSE":
      pop("CLOSE")
      e = expression
      pop("OPEN")
      
    case "Literal":
      e = literal
      
    case "Class":
      e = clazz
      
    case "DOT":
      e = dot
      
    default:
      throw ArgErr("Expected 'Identifier', 'CLOSE', 'Literal', 'Class' or 'DOT' at ${curInd} index, but got $n")
    }
    return e
  }
  
  private Expression literal() {
    b := pop("Literal")
    bi := blocks0.size
    sb := StrBuf()
    while ("Char" == peek.name) {
      sb.insert(0, text[pop("Char").range])
    }
    t := refine(sb.toStr)
    if (t.isEmpty) {
      throw ArgErr("Got empty literal at $b.range range in the text, block index: $bi")
    }
    return E.t(t)
  }
  
  private Str refine(Str text) {
    text
      .replace("\\\\", "\\")
      .replace("\\t", "\t")
      .replace("\\n", "\n")
      .replace("\\r", "\r")
      .replace("\\'", "'")
      .replace("\\[", "[")
      .replace("\\]", "]")
      .replace("\\\"", "\"")      
  }
  
  private Expression clazz() {
    pop("Class")
    rl := Range[,]
    while("Range" == peek.name) {
      rl.add(range)
    }
    if (rl.isEmpty) {
      throw ArgErr("Got empty Class expression at $curInd index")
    }
    return E.clazz(rl.reverse)
  }
  
  private Range range() {
    b := pop("Range")
    bc := pop("Char")
    c := refine(text[bc.range])
    if (1 != c.size) {
      throw ArgErr("Expected a single character at $bc.range interval in the text, but got ${text[bc.range]}")
    }
    if ("Char" == peek.name) {
      // range of a-z form
      bs := pop("Char")
      s := refine(text[bs.range])
      if (1 != s.size) {
        throw ArgErr("Expected a single character at $bs.range interval in the text, but got ${text[bs.range]}")
      }
      return s[0]..c[0]
    } else {
      // single-char range      
      return c[0]..c[0]
    }
  }
  
  private Expression dot() {
    b := pop("DOT")
    dt := text[b.range]
    if ('.' != dt[0]) {
      throw ArgErr("Expected '.' symbol at $b.range.min position in the text, but got ${dt[0]}")
    }    
    return E.any
  }
  
  private Expression nt() { 
    nt := text[pop("Identifier").range].trim
    return E.nt(nt)    
  }
}
