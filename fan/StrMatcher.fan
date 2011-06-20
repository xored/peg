
@Js
internal class StrMatcher : AbstractMatcher {  
  const Str content
  protected Int cursor
  private Int size
  
  private Int[] stateStack := [,]
  
  new make(Str content, Grammar[] gs) : super(gs) {
    this.content = content
    this.size = content.size
    this.cursor = 0
  }
  
  override Void pushState() {
    stateStack.push(cursor)
  }
  
  override Void popState(Bool drop) {
    Int state := stateStack.pop
    if (!drop) {
      cursor = state      
    }
  }

  override Bool match(Rule rule) {  
    cursor := this.cursor
    if (rule.exec(this)) {
      return true
    }
    this.cursor = cursor
    return false
  }
  
  override Bool char(Int char) {
    if (cursor < size && content[cursor] == char) {
      cursor ++
      return true
    }
    return false
  }
  
  override Bool str(Str str) {
    Int len := str.size
    if (cursor+len-1 < size && content[cursor..<cursor+len].equals(str)) {
      cursor += len
      return true
    }
    return false
  }
  
  override Bool range(Range r) {
    if (cursor < content.size
          && r.contains(content[cursor])) {
      cursor ++
      return true
    }
    return false
  }
  
  override Bool skip() {
    if (cursor < content.size) {
      cursor ++
      return true
    }
    return false
  }
  
  override Bool end() {
    return cursor >= content.size
  }
}