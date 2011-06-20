
@Js
internal class GrammarContext {
  Str grammarText := ""
  Str:Str deps := [:]
}

@Js
final const class Grammar : RuleResolver {
  internal const Str:Rule map
  
  const Rule start
  const Rule[] rules
  const Str namespace
  const Str[] dependencies
  
  new fromStr(Str grammarText) {
    Block? grammarRoot := Parser(PegGrammar.Grammar).tree(grammarText)
    if (grammarRoot == null) throw ArgErr("Grammar contains errors")

    if (grammarRoot.children[1].children.isEmpty) {
      namespace = ""
    } else {
      namespace = grammarText[grammarRoot.children[1].children[0].children[1].range]      
    }
    
    GrammarContext gc := GrammarContext { 
      it.grammarText = grammarText            
    }
    defs := grammar(grammarRoot, gc)
    
    Rule[] rules := [,]
    Str:Rule map := [:]
    defs.each { 
      rules.add(it.rule)
      if (null != map[it.name]) {
        throw ArgErr("Duplicate rule: $it.name")
      }
      map[it.name] = it.rule
    }
    this.start = rules[0]
    this.rules = rules
    this.map = map
    this.dependencies = gc.deps.keys
  }
  
  Str[] ruleNames() {
    map.keys
  }
  
  override Rule? rule(Str name, Str namespace) {
    Rule? ret := null
    if (namespace == this.namespace || namespace.isEmpty) {
      ret = map[name]      
    }
    return ret
  }
  
  override Str? name(Rule rule) {
    Str? shortName := map.eachWhile |r, n| { r == rule ? n : null }    
    return null == shortName ? null : NameParser.fullName(shortName, namespace)
  }
  
  private RuleDef[] grammar(Block block, GrammarContext gc) {
    return block.children[2].children.map {definition(it, gc)}
  }
  
  private RuleDef definition(Block block, GrammarContext gc) {
    return RuleDef(
      gc.grammarText[block.children[0].children[0].range], 
      expression(block.children[2], gc))
  }
  
  private Rule expression(Block block, GrammarContext gc) {
    if (block.children[1].children.isEmpty) {
      return sequence(block.children[0], gc)
    }
    list := [sequence(block.children[0], gc)]
    block.children[1].children.each {list.add(sequence(it.children[1], gc))}
    return FirstOfRule(list)
  }
  
  private Rule sequence(Block block, GrammarContext gc) {
    if (block.children.size == 1) {
      return prefix(block.children[0], gc)
    }
    rules := block.children.map |Block b->Rule| {prefix(b, gc)}
    return SeqRule(rules)
  }

  private Rule prefix(Block block, GrammarContext gc) {
    if (block.children[0].children.isEmpty) {
      return suffix(block.children[1], gc)
    }
    switch(block.children[0].children[0].children[0].rule) {
      case PegGrammar.AND: return TestRule(suffix(block.children[1], gc))
      case PegGrammar.NOT: return TestNotRule(suffix(block.children[1], gc))
    }
    throw Err("Grammar contains errors")
  }
  
  private Rule suffix(Block block, GrammarContext gc) {
    if (block.children[1].children.isEmpty) {
      return primary(block.children[0], gc)
    }
    switch(block.children[1].children[0].children[0].rule) {
      case PegGrammar.QUESTION: return ZeroOrOneRule(primary(block.children[0], gc))
      case PegGrammar.PLUS: return OneOrMoreRule(primary(block.children[0], gc))
      case PegGrammar.STAR: return ZeroOrMoreRule(primary(block.children[0], gc))
    }
    throw Err("Grammar contains errors")
  }
  
  private Rule primary(Block block, GrammarContext gc) {
    child := block.children[0]
    switch(child.rule) {
      case PegGrammar.IdExpr: return ref(child.children[0].children[0], gc)
      case PegGrammar.ParenExpr: return expression(child.children[1], gc)
      case PegGrammar.Literal: return literal(child, gc)
      case PegGrammar.Class: return clazz(child, gc)
      case PegGrammar.DOT: return dot(block)
    }
    throw Err("Grammar contains errors")
  }
  
  private Rule ref(Block block, GrammarContext gc) {
    RefRule ret := RefRule(this, gc.grammarText[block.range])
    if (!ret.namespace.isEmpty) {
      gc.deps.set(ret.namespace, "")
    }
    return ret
  }
  
  private Rule literal(Block block, GrammarContext gc) {
    pattern := gc.grammarText[block.children[0].children[1].range]
        .replace("\\\\", "\\")
        .replace("\\t", "\t")
        .replace("\\b", "\b")
        .replace("\\n", "\n")
        .replace("\\r", "\r")
        .replace("\\f", "\f")
        .replace("\\'", "'")
        .replace("\\\"", "\"")
    return LiteralRule(pattern)
  }
  
  private Rule clazz(Block block, GrammarContext gc) {
    PrimaryRule[] list := block.children[1].children.map 
      |Block b -> PrimaryRule| {
        range(b.children[1].children[0], gc)
      }
    return ClassRule(list)
  }
  
  private PrimaryRule range(Block block, GrammarContext gc) {
    if (block.rule == PegGrammar.Char) {
      return char(block, gc)
    }
    range := Range.makeInclusive(
      gc.grammarText[block.children[0].range].chars[0], 
      gc.grammarText[block.children[2].range].chars[0])
    return RangeRule(range)
  }

  private CharRule char(Block block, GrammarContext gc) {
    switch(block.children[0].rule) {
      case PegGrammar.EscapeChar:
        Int? char 
        switch (gc.grammarText[block.children[0].range].chars[1]) {
          case 'n': char = '\n'
          case 'r': char = '\r'
          case 't': char = '\t'
          case '\'': char = '\''
          case '"': char = '"'
          case '[': char = '['
          case ']': char = ']'
          case '\\': char = '\\'
        }
        return CharRule(char)
      case PegGrammar.Unicode:
        code := gc.grammarText[block.children[0].range][2..-1]
        return CharRule(code.toInt(16))
      case PegGrammar.SimpleChar: 
        return CharRule(gc.grammarText[block.children[0].range].chars[0])
    }
    throw Err("Grammar contains errors")
  }
  
  private SkipRule dot(Block block) {
    return SkipRule()
  }
}
