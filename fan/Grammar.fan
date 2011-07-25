
** Grammar is a set of expression associated with non-terminal symbols and the starting expression. 
@Js
internal const mixin Grammar
{
  
  ** Matches non-terminal symbols of the grammar (keys) with corresponding expressions (values).
  abstract Str:Expression rules()
  
  ** Non-terminal, which denotes starting expression of the grammar.
  ** 
  ** In the original PEG paper, starting expression may be by its own, without non-terminal.
  ** But this is inconvenient to work with. 
  abstract Str start()
  
}

@Js
internal const class GrammarImpl : Grammar 
{  
  override const Str:Expression rules  
  override const Str start
  
  new make(Str start, Str:Expression rules) {
    this.rules = rules
    this.start = start
  }
  
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
