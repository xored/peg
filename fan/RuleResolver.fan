
@Js
class NameParser {
  static const Str nsSeparator := ":"
  static const Int nsPart := 1
  static const Int namePart := 0
  
  static Str[] nameParts(Str fullName) {
    Int? nsIndex := fullName.index(nsSeparator)
    Str namespace := ""
    Str name := ""
    if (null != nsIndex) {
      namespace = fullName[0..<nsIndex]
      name = fullName[nsIndex+nsSeparator.size..<fullName.size] 
    } else {
      name = fullName
    }
    return [name, namespace]
  }
  
  static Str? fullName(Str? shortName, Str namespace) {
    namespace.isEmpty ? shortName : namespace + nsSeparator + shortName
  }
  
  private new make() {}
}

@Js
mixin RuleResolver
{
  static const Rule[] emptyKids := [,]
  abstract Rule? rule(Str name, Str namespace)
  
  abstract Str? name(Rule rule)  
  
  virtual Rule[] kids(Rule rule) {
    (rule as RuleContainer)?.kids(this) ?: emptyKids
  }
}

@Js
class MultiGrammarResolver : RuleResolver 
{
  private Str:Grammar grammars := [:]
  private Grammar[] grammarsList
  
  new make(Grammar[] gs) {
    this.grammarsList = gs
    gs.each {
      Str k := it.namespace
      if (grammars.containsKey(k)) {
        throw ArgErr(k.isEmpty ? "Two or more grammars with the empty namespace" : "Duplicate namespace: '$k'")
      }
      grammars[k] = it
    }
  }
  
  override Rule? rule(Str name, Str namespace) {
    return grammars[namespace]?.rule(name, namespace)
  }
  
  override Str? name(Rule rule) {
    grammarsList.eachWhile { it.name(rule) }
  }
}
