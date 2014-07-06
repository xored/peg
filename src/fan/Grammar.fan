
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
  
  ** Namespace of the grammar
  abstract Str namespace()
  
  ** Namespaces from which the grammar depends
  abstract Str[] dependencies()

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
  override const Str namespace
  
  ** Namespaces from which the grammar depends
  override const Str[] dependencies
  
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
  override const Str namespace
  override const Str[] dependencies
  
  new make(Str start, Grammar[] grammars) {
    this.start = start
    t := Str:Grammar[:]
    ns := ""
    deps := [,]
    grammars.each {
      if (null == t[it.namespace]) {
        if(it.start.equals(start)) {
          //we found base grammar
          ns = it.namespace
          deps = it.dependencies
        }
        t[it.namespace] = it        
      } else {
        throw ArgErr("Duplicate ${moduleName(it.namespace)}")
      }
    }
    this.grammars = t
    this.namespace = ns
    this.dependencies = deps
  }
  
  override Str[] nonterminals() { 
    ret := Str[,]
    grammars.vals.each { ret.addAll(it.nonterminals) }
    return ret
  }
  
  private Str extractNamespace(Str nt) {
    ci := nt.index(":")
    return (null == ci) ? "" : nt[0..<ci]
  }
  
  @Operator override Expression? get(Str nt) {
    ns := extractNamespace(nt)
    g := grammars[ns]
    if (null == g) {
      g = grammars.find { it.nonterminals.contains(nt) }
    }
    return g?.get(nt)
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
