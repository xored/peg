
@Js
internal abstract class AbstractMatcher : Matcher
{
  private MultiGrammarResolver mga
  
  new make(Grammar[] gs) {
    mga = MultiGrammarResolver(gs)
  }
  
  override Rule? rule(Str name, Str namespace) {
    mga.rule(name, namespace)
  }
  
  override Str? name(Rule rule) {
    mga.name(rule)
  }
}
