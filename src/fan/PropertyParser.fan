
@Js
const class PropertySet {
  const Str name 
  const Str:Str properties 
  
  new make(Str name, Str:Str props) {
    this.name = name
    this.properties = props
  }
  
  override Str toStr() {
    "$name { $properties }"
  }
}

** Parser for CSS-like properties text.
** 
** This format is good for assigning various properties to grammar rules. Later, such properties
** files may be used in conjunction with grammar files to parse text and perform tasks on rule blocks
** according to the rules' properties.
@Js
class PropertyParser
{
  private Grammar grammar
  
  new make() {
    // more simple versions of the following line (such as Pod.of(this).uri + `/res/props-grammar.txt`)
    // don't work when compiled into jar
    Uri loc := Pod.of(this).uri.plusSlash.plusName("res").plusSlash.plusName("props-grammar.txt")
    grammar = Grammar.fromStr(loc.get->readAllStr)
  }
  
  PropertySet[] parse(Str input, Str defaultNamespace := "") {
    PropertyHandler handler := PropertyHandler()
    handler.input = input
    handler.defaultNamespace = defaultNamespace
    
    root := Parser.tree(grammar, input.toBuf)
    traverse(handler, root)
    PropertySet[] ret := [,]
    handler.propertySets.vals.each {
      ret.add(it.toPropertySet)
    }
    return ret    
  }
  
  private Void traverse(PropertyHandler h, BlockNode b) {
    h.visit(b)
    b.kids.each { traverse(h, it) }
  }
}

@Js
internal class MutablePropSet {
  Str name := ""
  Str:Str properties := [:]
  
  PropertySet toPropertySet() {
    PropertySet(name, properties)
  }
}

@Js
internal class PropertyHandler {
  static const Str STYLE_NAME := "Name"
  static const Str STYLE_NAMESPACE := "Namespace"
  static const Str PROP_NAME := "PropName"
  static const Str PROP_VALUE := "PropValue"
  static const Str PROPS_END := "PropListEnd"
  
  Str? input := null
  Str defaultNamespace := ""
  Str:MutablePropSet propertySets := [:]
  
  private MutablePropSet[] currentPropSets := [,]
  private Str currentPropName := ""
  private Str currentNamespace := ""
  
  Void visit(BlockNode bn) {
    block := bn.block
    blockContent := input[block.range].trim
    if (STYLE_NAMESPACE.equals(block.name)) {
      currentNamespace = blockContent
    }
    else if (STYLE_NAME.equals(block.name)) {
      fullName := makeFullName(blockContent)
      MutablePropSet? t := propertySets.get(fullName, null)
      if (null == t) {
        t = MutablePropSet()
        propertySets[fullName] = t
        t.name = fullName
      }      
      if (!currentPropSets.contains(t)) {
        currentPropSets.add(t);
      }
    }
    else if (PROP_NAME.equals(block.name)) {
      currentPropName = blockContent;
    }
    else if (PROP_VALUE.equals(block.name)) {
      v := polish(blockContent)
      currentPropSets.each { 
        it.properties[currentPropName] = v 
      }
    }
    else if (PROPS_END.equals(block.name)) {
      currentPropSets.clear
    }
  }
  
  private Str polish(Str v) { v.replace(";;", ";") }
  
  private Str makeFullName(Str name) {
    ns := currentNamespace.isEmpty ? defaultNamespace : currentNamespace
    return ns.isEmpty ? name : "$ns:$name"
  }
}
