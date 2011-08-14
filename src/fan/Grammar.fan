
** Grammar is a set of expression associated with non-terminal symbols and the starting expression. 
const mixin Grammar
{
  
  ** Returns an expression associated with the given nonterminal, or 'null', if not found.
  @Operator abstract Expression? get(Str nonterminal)

  ** Returns all nonterminals in the grammar. The list returned should be immutable.
  abstract Str[] nonterminals()
  
  ** Non-terminal, which denotes starting expression of the grammar.
  ** 
  ** In the original PEG paper, starting expression may be by its own, without non-terminal.
  ** But this is inconvenient to work with. 
  abstract Str start()

  ** Parses a grammar text and returns the parsed grammar. 
  ** May throw ParseErr.
  static Grammar fromStr(Str grammar) {
    lh := ListHandler()
    p := Parser(MetaGrammar.val, lh).run(grammar.toBuf)
    if (MatchState.success != p.match.state) {
      throw ParseErr("Failed to parse grammar: $p.match")
    }
    return GrammarBuilder.run(grammar, lh.blocks)
  }
}

const class GrammarImpl : Grammar 
{  
  private const Str:Expression rules
  
  override const Str start
  
  new make(Str start, Str:Expression rules) {
    this.rules = rules
    this.start = start
  }
  
  @Operator override Expression? get(Str nonterminal) { rules[nonterminal] }
  
  override Str[] nonterminals() { rules.keys }
  
  override Str toStr() {
    sb := StrBuf()
    sb.add("GrammarImpl(start=")
    sb.add(start)
    sb.add(", rules:\n")
    rules.each |e, nt| {
      sb.add("  ")
      sb.add(nt)
      sb.add(": ")
      sb.add(e)
      sb.add("\n")
    }
    sb.add(")")
    return sb.toStr
  }
  
  override Int hash() { 
    p := 31
    r := p + rules.hash
    r = r*p + start.hash
    return r
  }
  
  override Bool equals(Obj? other) {
    if (null == other || this.typeof != other.typeof) {
      return false
    }
    o := other as GrammarImpl
    return start == o.start && rules == o.rules
  }
}
