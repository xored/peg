
@Js
const mixin Rule {
  internal abstract Bool exec(Matcher matcher)
}

@Js
const mixin RuleContainer {
  abstract Rule[] kids(RuleResolver ra)
}

@Js
internal const abstract class AbstractRule : Rule {
  const Str? source
  
  new make(Str? source := null) {
    this.source = source
  }
  
  override Str toStr() {
    source ?: defStr
  }
  
  abstract Str defStr()
}

@Js
internal const class RuleDef {
  
  const Str name
  const Rule rule
  
  new make(Str name, Rule rule) {
    this.name = name
    this.rule = rule
  }
}

@Js
internal const abstract class MultiRule : AbstractRule, RuleContainer
{
  const Rule[] rules
  
  new make(Rule[] rules, Str? source := null) : super(source) {
    this.rules = rules
  }
  
  override Rule[] kids(RuleResolver ra) {
    rules
  }
}

@Js
internal const abstract class SingleRule : AbstractRule, RuleContainer
{
  private const Rule[] kidList
  const Rule rule
  
  new make(Rule rule, Str? source := null) : super(source) {
    this.rule = rule    
    kidList = [rule]
  }
  
  override Rule[] kids(RuleResolver ra) {
    kidList    
  }
}

@Js
internal const class FirstOfRule : MultiRule
{ 
  new make(Rule[] rules, Str? source := null) : super(rules, source) {}
  
  override Bool exec(Matcher matcher) {
    rules.any { matcher.match(it) }
  }
  
  override Str defStr() {
    "(" + rules.join(" / ") + ")"      
  }
}

@Js
internal const class SeqRule : MultiRule
{ 
  new make(Rule[] rules, Str? source := null) : super(rules, source) {}
  
  override Bool exec(Matcher matcher) {
    matcher.pushState
    Bool ret := false
    try {
      ret = rules.all { matcher.match(it) }      
    } finally {
      matcher.popState(ret)
    }
    return ret
  }
  
  override Str defStr() {
    "(" + rules.join(" ") + ")"      
  }
}

@Js
internal const class RepeatRule : SingleRule
{
  const Int lower
  const Int upper
  
  new make(Rule rule, Int lower, Int upper, Str? source := null)
      : super(rule, source) {
    if (lower < 0) throw ArgErr("Lower bound must be >= 0")
    if (upper == 0) throw ArgErr("Upper bound must be != 0")
    this.lower = lower
    this.upper = upper
  }
  
  override Bool exec(Matcher matcher) {
    Int count := 0
    while(upper < 0 || count < upper) {
      if (matcher.match(rule)) count++
      else {
        if (count >= lower) {
          return true
        } else {
          return false
        }
      }
    }
    return true
  } 
  
  override Str defStr() {
    if (lower == 0 && upper == 1) return "$rule?"
    if (lower == 0 && upper < 0) return "$rule*"
    if (lower == 1 && upper < 0) return "$rule+"
    return "$rule[$lower:$upper]"
  }
}

@Js
internal const class ZeroOrMoreRule : RepeatRule {
  new make(Rule rule, Str? source := null) : super(rule, 0, -1, source) {}
}

@Js
internal const class OneOrMoreRule : RepeatRule {
  new make(Rule rule, Str? source := null) : super(rule, 1, -1, source) {}
}

@Js
internal const class ZeroOrOneRule : RepeatRule {
  new make(Rule rule, Str? source := null) : super(rule, 0, 1, source) {}
}

@Js
internal const mixin LazyRuleProvider {
  abstract Rule rule()
}

@Js
internal const class LazyRule : AbstractRule, RuleContainer {
  const LazyRuleProvider ruleProv
  
  new make(LazyRuleProvider ruleProv, Str? source := null) : super(source) {
    this.ruleProv = ruleProv
  }
  
  override Bool exec(Matcher matcher) {
    matcher.match(ruleProv.rule)
  }
  
  override Rule[] kids(RuleResolver ra) {
    [ruleProv.rule]
  }
  
  override Str defStr() {
    ruleProv.rule.toStr
  }
}

@Js
internal const class TestNotRule : SingleRule
{
  new make(Rule rule, Str? source := null) : super(rule, source) {}
  
  override Bool exec(Matcher matcher) {
    matcher.pushState
    try {
      return !matcher.match(rule)      
    } finally {
      matcher.popRestore
    }
  } 
  
  override Str defStr() {"!$rule"}
}

@Js
internal const class TestRule : SingleRule {
  new make(Rule rule, Str? source := null) : super(rule, source) {}
  
  override Bool exec(Matcher matcher) {
    matcher.pushState
    try {
      return matcher.match(rule)      
    } finally {
      matcher.popRestore
    }
  } 
  
  override Str defStr() {"&$rule"}
}

@Js
internal const abstract class PrimaryRule : AbstractRule {
  new make(Str? source := null) : super(source) {}
}

@Js
internal const class LiteralRule : AbstractRule
{
  const Int[] chars
  const Str pattern
  
  new make(Str pattern, Str? source := null) : super(source) {
    this.pattern = pattern
    this.chars = pattern.chars
  }
  
  override Bool exec(Matcher matcher) {
    matcher.pushState
    Bool ret := false
    try {
      ret = chars.all { matcher.char(it) }      
    } finally {
      matcher.popState(ret)
    }
    return ret
  }  
  
  override Str defStr() {
      "'" + pattern
        .replace("\\", "\\\\")
        .replace("\t", "\\t")
        .replace("\b", "\\b")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\f", "\\f")
        .replace("'", "\\'")
        .replace("\"", "\\\"") + "'"      
  }
}

@Js
internal const class CharRule : PrimaryRule
{
  const Int char
  
  new make(Int char, Str? source := null) : super(source) {
    this.char = char
  }
  
  override Bool exec(Matcher matcher) {
    matcher.char(char)
  }  
  
  override Str defStr() {
    switch (char) {
      case '\\': return "\\\\"
      case '\t': return "\\t"
      case '\b': return "\\b"
      case '\n': return "\\n"
      case '\r': return "\\r"
      case '\f': return "\\f"
      case '\'': return "\\'"
      case '"': return "\\\""
      case '[': return "\\["
      case ']': return "\\]"
      default: return Str.fromChars([char])
    }
  }
}

@Js
internal const class RangeRule : PrimaryRule
{
  const Range range
  
  new make(Range range, Str? source := null) : super(source) {
    if (range.exclusive) throw Err("Invalid range")
    this.range = range
  }
  
  override Bool exec(Matcher matcher) {
    matcher.range(range)
  }  
  
  override Str defStr() {
    range.start.toChar + "-" + range.end.toChar    
  }
}

@Js
internal const class ClassRule : AbstractRule, RuleContainer {
  const PrimaryRule[] rules
  new make(PrimaryRule[] rules, Str? source := null) : super(source) {
    this.rules = rules
  }
  
  override Bool exec(Matcher matcher)//, Problems problems)
  {
    rules.any { matcher.match(it) }
  }
  
  override Str defStr() {
    "[" + rules.join("", |r->Str| { r.defStr }) + "]"
  }
  
  override Rule[] kids(RuleResolver ra) { rules }
}

@Js
internal const class SkipRule : AbstractRule
{
  new make(Str? source := null) : super(source) {}
  
  override Bool exec(Matcher matcher) {
    matcher.skip
  } 
  
  override Str defStr() {"."}
}

@Js
internal const class RefRule : Rule, RuleContainer {
  private static const Str nsSeparator := ":"
  
  const Str name
  const Grammar grammar
  const Str namespace
  
  new make(Grammar grammar, Str fullName) {
    this.grammar = grammar
    
    Str[] parts := NameParser.nameParts(fullName)
    namespace = parts[NameParser.nsPart]
    name = parts[NameParser.namePart]
  }
  
  override Bool exec(Matcher matcher) {
    return matcher.match(getRefRule(matcher))
  }
  
  override Rule[] kids(RuleResolver ra) {
    [getRefRule(ra)]        
  }
  
  override Str toStr() {name}
  
  Rule? getRefRule(RuleResolver ra) {
    Rule? rule := grammar.rule(name, namespace)
    if (null == rule) {
      rule = ra.rule(name, namespace)
      if (null == rule) {
        throw ArgErr("Rule not found: $name")
      }
    }
    return rule
  }
}
