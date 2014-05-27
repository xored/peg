
** Grammar is a set of expression associated with non-terminal symbols and the starting expression. 
@Js
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

** General implementation of Grammar.
@Js
const class GrammarImpl : Grammar 
{  
  private const Str:Expression rules
  
  override const Str start  
  ** Namespace of the grammar
  const Str namespace
  ** Namespaces from which the grammar depends
  const Str[] dependencies    
  
  new make(Str start, Str:Expression rules, Str namespace := "", Str[] dependencies := Str[,]) {
    this.rules = rules
    this.start = start
    this.namespace = namespace
    this.dependencies = dependencies
  }
  
  @Operator override Expression? get(Str nonterminal) { rules[nonterminal] }
  
  override Str[] nonterminals() { rules.keys }
  
  override Str toStr() {
    sb := StrBuf()
    sb.add("GrammarImpl(start=")
    sb.add(start)
    sb.add(", namespace")
    if (namespace.isEmpty) {
      sb.add(" is empty")
    } else {
      sb.add("=")
      sb.add(namespace)
    }
    sb.add(", dependencies: ")
    if (dependencies.isEmpty) {
      sb.add("no, ")
    } else {
      dependencies.each {
        sb.add(it)
        sb.add(", ")
      }
    }
    sb.add("rules:\n")
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
    r = r*p + namespace.hash
    r = r*p + dependencies.hash
    return r
  }
  
  override Bool equals(Obj? other) {
    if (null == other || this.typeof != other.typeof) {
      return false
    }
    o := other as GrammarImpl
    return start == o.start && rules == o.rules && namespace == o.namespace && dependencies == o.dependencies 
  }
}

** MultiGrammar combines multiple GrammarImpl instances
@Js
const class MultiGrammar : Grammar
{  
  private const Str:Grammar grammars
  
  override const Str start
  
  new make(Str start, GrammarImpl[] grammars) {
    this.start = start
    t := Str:Grammar[:]
    grammars.each {
      if (null == t[it.namespace]) {
        t[it.namespace] = it        
      } else {
        throw ArgErr("Duplicate ${moduleName(it.namespace)}")
      }
    }
    this.grammars = t
  }
  
  override Str[] nonterminals() { 
    ret := Str[,]
    grammars.vals.each { ret.addAll(it.nonterminals) }
    return ret
  }
  
  @Operator override Expression? get(Str nt) {
    ci := nt.index(":")
    if (null == ci) {      
      return grammars[""][nt]
    } else {      
      return grammars[nt[0..<ci]]?.get(nt)
    }
  }
  
  private static Str moduleName(Str namespace) {
    if (namespace.isEmpty) {
      return "default namespace"
    } else {
      return "$namespace namespace"
    }
  }
  
  override Str toStr() {
    sb := StrBuf()
    sb.add("MultiGrammar(start=$start, sub-grammars:\n")
    grammars.vals.each { 
      sb.add(it)
      sb.add("\n")
    }
    return sb.toStr
  }
}
