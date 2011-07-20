
** PEG meta-grammar.
** This grammar is described in the original PEG paper 
** (http://pdos.csail.mit.edu/~baford/packrat/popl04/).
** Non-terminals symbols are the same as in the paper.

// Actually, meta grammar should be a singleton. 
// But Fantom has troubles with static variables initialization order 
// (at least in JS, http://fantom.org/sidewalk/topic/1381). And some expressions are singletons.
// So, to avoid hard bugs, let the meta grammar be a normal class.
// Performance overhead is not important.
@Js
internal const class MetaGrammar : Grammar
{
  override const Str:Expression rules
  
  override const Expression start

  new make() {
    rules = createMetaRules
    start = rules["Grammar"]
  }

  ** Create a map of meta grammar rules.
  private static Str:Expression createMetaRules() {
    tmp := Str:Expression[:]
    
    // Lexical syntax =========================================================
    
    eof := E.not(E.any)
    tmp["EndOfFile"] = eof
    
    eoln := E.choice(["\r\n", "\n", "\r"])
    tmp["EndOfLine"] = eoln
    
    space := E.choice([" ", "\t", eoln])
    tmp["Space"] = space
    
    comment := E.seq(["#", E.rep([E.not(eoln), E.any]), eoln])
    tmp["Comment"] = comment
    
    spacing := E.rep([space, comment])
    tmp["Spacing"] = spacing
    
    dot := E.seq([".", spacing])
    tmp["DOT"] = dot
    
    close := E.seq([")", spacing])
    tmp["CLOSE"] = close
    
    open := E.seq(["(", spacing])
    tmp["OPEN"] = open
    
    plus := E.seq(["+", spacing])
    tmp["PLUS"] = plus
    
    star := E.seq(["*", spacing])
    tmp["STAR"] = star
    
    question := E.seq(["?", spacing])
    tmp["QUESTION"] = question
    
    not := E.seq(["!", spacing])
    tmp["NOT"] = not
    
    and := E.seq(["&", spacing])
    tmp["AND"] = and
    
    slash := E.seq(["/", spacing])
    tmp["SLASH"] = slash
    
    leftarrow := E.seq(["<-", spacing])
    tmp["LEFTARROW"] = leftarrow

    char := E.choice([
      ["\\", "n", "r", "t", "'", "\"", "[", "]", "\\"],
      [E.not("\\"), E.any]
    ]) // TODO: implement character code support such as \213 here
    tmp["Char"] = char
    
    range := E.choice([
      [char, E.t("-"), char],
      char
    ])
    tmp["Range"] = range
    
    clazz := E.seq(["[", E.rep(["]", range]), "]", spacing])
    tmp["Class"] = clazz
    
    literal := E.choice([
      ["'", E.rep([E.not("'"), char]), "'", spacing],
      ["\"", E.rep([E.not("'"), char]), "\"", spacing]
    ])
    tmp["Literal"] = literal
  
    identStart := E.seq(['a'..'z', 'A'..'Z', "-"])
    tmp["IdentStart"] = identStart
    
    identCont:= E.choice([identStart, '0'..'9'])
    tmp["IdentCont"] = identCont
    
    identifier := E.seq([identStart, E.rep(identCont), spacing])
    tmp["Identifier"] = identifier
    
    // Hierarchical syntax ====================================================
    
    primary := E.choice([
      [identifier, E.not(leftarrow)],
      [open, E.nt("Expression"), close],
      literal,
      clazz,
      dot
    ])
    tmp["Primary"] = primary
    
    suffix := E.seq([primary, E.opt(E.choice([question, star, plus]))])
    tmp["Suffix"] = suffix
    
    prefix := E.seq([E.opt([and, not]), suffix])
    tmp["Prefix"] = prefix
    
    sequence := E.rep(prefix)
    tmp["Sequence"] = sequence
    
    expression := E.seq([sequence, E.rep([slash, sequence])])
    tmp["Expression"] = expression
    
    definition := E.seq([identifier, leftarrow, expression])
    tmp["Definition"] = definition
    
    grammar := E.seq([spacing, E.rep1(definition), eof])
    tmp["Grammar"] = grammar
    
    return tmp
  }
}
