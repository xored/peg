
** Builds Grammar instance from the given blocks list.
** Blocks in the list must be in specific order described by MetaGrammar
@Js
internal class GrammarBuilder
{
  
  ** Constructs Grammar from the given blocks and the grammar's text.
  static Grammar run(Str text, Block[] blocks) { GrammarBuilder(text, blocks).grammar }

  private const Str text
  private Block[] blocks
  private Str:Expression rules := [:]
  private Str lastNt := ""
  
  private new make(Str text, Block[] blocks) {
    this.text = text
    this.blocks = skipUnused(blocks)
  }
  
  private static Block[] skipUnused(Block[] blocks) {
    ret := Block[,]
    skip := Str:Str ["EndOfLine":"", "Space":"", "Comment":"", "Spacing":"", "IdentStart":"", "IdentCont":"", "Char":""]
    blocks.each {
      if (null == skip[it.name]) {
        ret.add(it)
      }
    }
    return ret
  }
  
  private Void check(Str name) {
    b := blocks.peek
    if (null == b) {
      throw ArgErr("Expected $name block, but run out of blocks")
    }
    if (name != b.name) {
      throw ArgErr("Expected $name block at ${blocks.size-1} index, but got $b.name")      
    }
  }
  
  private Block pop(Str name) {
    check(name)
    return blocks.pop
  }
  
  private Block? popIf(Str name) {
    if (name == blocks.peek.name) {
      return blocks.pop
    } else {
      return null
    }
  }
  
  private Grammar grammar() {
    pop("Grammar")
    return eof
  }
  
  private Grammar eof() {
    pop("EndOfFile")
    while (!blocks.isEmpty) {
      definition
    }
    if (lastNt.isEmpty) {
      throw ArgErr("No rules found. Grammar can't be empty.")
    }
    return GrammarImpl(rules, lastNt)
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
    while ("Prefix" == blocks.peek.name) {
      elist.add(prefix)
    }
    if (elist.isEmpty) {
      elist.add(E.empty)
    }
    return 1 == elist.size ? elist.first : E.seq(elist) 
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
    } else {
      e = primary
    }
    return e
  }
  
  private Expression primary() {
    pop("Primary")
    n := blocks.peek.name
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
      throw ArgErr("Expected 'Identifier', 'CLOSE', 'Literal', 'Class' or 'DOT' at ${blocks.size-1} index, but got $n")
    }
    return e
  }
  
  private Expression literal() {
    b := pop("Literal")
    if (b.range.isEmpty) {
      throw ArgErr("Got empty literal at ${blocks.size} index")      
    }
    quote := text[b.range.min]
    if ('\'' != quote && '"' != quote) {
      throw ArgErr("Expected either ' or \" at $b.range.min position in the text, but got $quote")
    }
    if (quote != text[b.range.max]) {
      throw ArgErr("Expected $quote at $b.range.max position in the text, but got ${text[b.range.max]}")
    }
    start := b.range.min + 1
    end := b.range.max - 1
    if (start >= end) {
      throw ArgErr("Expected non-empty literal range (without quotes) at $blocks.size position, but got start=$start, end=$end")
    }
    return E.t(refine(text[start..end]))
  }
  
  private Str refine(Str text) {
    // TODO: check this refinement!
    text
      .replace("\\\\", "\\")
      .replace("\\t", "\t")
      .replace("\\b", "\b")
      .replace("\\n", "\n")
      .replace("\\r", "\r")
      .replace("\\f", "\f")
      .replace("\\'", "'")
      .replace("\\\"", "\"")      
  }
  
  private Expression clazz() {
    pop("Class")
    elist := Expression[,]
    while("Range" == blocks.peek.name) {
      elist.add(range)
    }
    if (elist.isEmpty) {
      throw ArgErr("Got empty Class expression at $blocks.size index")
    }
    return 1 == elist.size ? elist.first : E.choice(elist)
  }
  
  private Expression range() {
    b := pop("Range")
    if (b.range.isEmpty) {
      throw ArgErr("Got empty range at at $blocks.size index")
    }
    t := text[b.range]
    hyphensCount := 0
    hyphenIndex := -1
    t.each |c, i| {
      if ('-' == c) {
        ++hyphenIndex
        if (3 > hyphensCount) {
          hyphenIndex = i
        }
      }
    }
    if (3 < hyphensCount) {
      throw ArgErr("Invalid Range expression $t (block with $blocks.size index)")
    }
    Expression? e := null
    if (-1 != hyphenIndex) {
      // range is in 'a-z' form
      c1 := refine(t[0..<hyphenIndex])
      c2 := refine(t[hyphenIndex+1..t.size])
      if (1 != c1.size || 1 != c2.size) {
        throw ArgErr("Expected one symbol before and after -, but got $t")
      }
      e = E.range(c1[0]..c2[0])
    } else {
      // range is just a single char
      c := refine(t)
      if (1 != c.size) {
        throw ArgErr("Expected a single char, but got $t")
      }
      e = E.t(c)
    }
    return e
  }
  
  private Expression dot() {
    b := pop("DOT")
    if (1 != b.range.toList.size) {
      throw ArgErr("Expected DOT block with size 1, but got $b")
    }
    if ('.' != text[b.range.min]) {
      throw ArgErr("Expected '.' symbol at $b.range.min position in the text, but got ${text[b.range.min]}")
    }    
    return E.any
  }
  
  private Expression nt() { E.nt(text[pop("Identifier").range].trim) }  
}
