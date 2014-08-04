
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
  private Str ns := ""
  private Str[] deps := [,]
  private Str:Str[] sparse := [:]
  
  private new make(Str text, Block[] blocks) {
    this.text = text
    this.blocks0 = skipUnused(blocks)
    this.curInd = blocks0.size-1
  }
  
  private static Block[] skipUnused(Block[] blocks) {
    ret := Block[,]
    skip := Str:Str ["EndOfLine":"", "Space":"", "Comment":"", "Spacing":"", "IdentStart":"", "IdentCont":"", "Ident":"", "AT":"", "COLON":"", "HexDigit":""]
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
    // early check for namespace
    finishSize := 0
    if ("Namespace" == blocks0.first.name) {
      finishSize = 1
      nsb := blocks0.first
      ns = text[nsb.range]
      if (ns.isEmpty) {
        throw ArgErr("Got empty namespace at 0 block, text interval: $nsb.range")
      }
    }
    // definition loop
    while (finishSize <= curInd) {
      definition
    }
    // last checks
    if (lastNt.isEmpty) {
      throw ArgErr("No rules found. Grammar can't be empty.")
    }
    if (sparse.containsKey(lastNt)) {
      throw ArgErr("Grammar can't start with a sparse block")
    }
    return GrammarImpl(lastNt, rules, ns, deps)
  }
  
  private Void definition() {
    pop("Definition")
    if ("SparseBlock" == peek.name) {
      sparseBlock
    } else {
      e := expression
      pop("LEFTARROW")
      lastNt = definitionIdentifier
      rules[lastNt] = e
    }
  }
  
  private Str definitionIdentifier() { 
    ret := text[pop("DefinitionIdentifier").range]
    // DefinitionIdentifier can't have explicit namespace
    return ns.isEmpty ? ret : "$ns:$ret"    
  }
  
  private Void sparseBlock() {
    pop("SparseBlock")
    pop("CURLYCLOSE")
    rules := Str[,]
    while ("Definition" == peek.name) {
      definition
      rules.add(lastNt)
    }
    pop("CURLYOPEN")
    pop("LEFTARROW")
    lastNt = definitionIdentifier
    sparse[lastNt] = rules
  }
  
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
      e := prefix
      if (null != popIf("SparseCall")) {
        e = sparseCall(e)
      }
      elist.add(e)
    }
    if (elist.isEmpty) {
      elist.add(E.empty)
    }
    return 1 == elist.size ? elist.first : E.seq(elist.reverse) 
  }
  
  private Expression sparseCall(Expression tail) {
    pop("CURLYCLOSE")
    e := nt
    s := ((Nt)e).symbol
    pop("CURLYOPEN")
    rules := sparse.get(s, null)
    if (null == rules || rules.isEmpty) {
      throw ArgErr("Sparse block ${s} not found")
    }
    return E.sparseCall(rules.reverse.map { E.nt(it) }, tail)
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
    } else if (null != popIf("LazyRepetition")) {
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

    case "INDENT":
      e = indent

    case "DEDENT":
      pop("DEDENT")
      e = E.dedent
      
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
  
  private static Str unescapeUnicode(Str s) {
    buf := StrBuf()
    for (i := 0; i < s.size; ++i) {
      if ('\\' == s[i] && (0 == i || '\\' != s[i-1]) && i < s.size - 5 && 'u' == s[i+1]) {
        seq := ""
        if (i < s.size - 6 && s[i+6].isDigit(16)) {
          seq = s[i+2..i+6] 
          i += 6
        } else {
          seq = s[i+2..i+5] 
          i += 5
        }
        escaped := Int.fromStr(seq, 16, false)
        if (null == escaped) {
          throw ArgErr("Invalid unicode escape sequence. Expected \\uNNNN, but got $seq")
        }
        if (escaped > 0xFFFF) {
          escaped -= 0x10000
          buf.addChar(0xD800 + escaped.shiftr(10))
          buf.addChar(0xDC00 + escaped.and(0x3FF))
        } else {
          buf.addChar(escaped)
        }
      } else {
        buf.addChar(s[i])
      }
    }
    return buf.toStr
  }
  
  private static Str refine(Str text) {
    ret := text
      .replace("\\\\", "\\")
      .replace("\\t", "\t")
      .replace("\\n", "\n")
      .replace("\\r", "\r")
      .replace("\\'", "'")
      .replace("\\[", "[")
      .replace("\\]", "]")
      .replace("\\\"", "\"")
    return unescapeUnicode(ret)
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
    symbol := text[pop("Identifier").range]
    si := symbol.index(":")
    if (null == si) {
      if (!ns.isEmpty) {
        symbol = "$ns:$symbol"        
      }
    } else {
      symbolNs := symbol[0..<si]
      if (ns != symbolNs && !deps.contains(symbolNs)) {
        deps.add(symbolNs)
      }
    }
    return E.nt(symbol)    
  }

  private Expression indent() {
    pop("INDENT")
    if (null != popIf("CLOSE")) { // Got an indent with a custom rule
      rule := (Nt) nt
      pop("OPEN")
      return E.indent(rule.symbol)
    }
    // Got an ordinary whitespace indent
    return E.indent
  }
}
