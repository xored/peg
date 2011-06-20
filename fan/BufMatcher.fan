
@Js
internal const class BufMatcherState {
  const Int bytePos
  const Int charPos
  
  new make(Int bytePos, Int charPos) {
    this.bytePos = bytePos
    this.charPos = charPos
  }
}

@Js
internal class BufMatcher : AbstractMatcher {
  private Buf buf
  private Int charPos := 0
  private BufMatcherState[] stateStack := [,]
  private Handler handler
  
  new make(Buf buf, Handler handler, Grammar[] gs) : super(gs) {
    this.buf = buf
    this.handler = handler
  }
  
  override Void pushState() {
    stateStack.push(BufMatcherState(buf.pos, charPos))
    handler.push
  }

  override Void popState(Bool drop) {
    BufMatcherState state := stateStack.pop
    if (!drop) {
      buf.seek(state.bytePos)
      charPos = state.charPos
    }
    handler.pop(drop)
  }
  
  override Bool match(Rule rule) {
    safeCall |->Bool| {
      oldCharPos := charPos
      Bool ret := false
      ret = rule.exec(this)
      if (ret) {
        b := Block(rule, oldCharPos, null)
        b.end = charPos
        handler.visit(b)
      }      
      return ret      
    }
  }
  
  override Bool char(Int char) {
    safeCall |->Bool| {
      Int? c := safeReadChar
      Bool ret := c == char
      if (ret) {
        ++charPos      
      }
      return ret
    }
  }
  
  override Bool str(Str str) {
    safeCall |->Bool| {
      Int len := str.size
      Bool ret := false
      try {
        Str s := buf.readChars(len)
        ret = s == str
        if (ret) {
          charPos += s.size
        }
      } catch (IOErr e) {
        // buf is at the end -- not an exception, ret is false
      }
      return ret
    }
  }
  
  override Bool range(Range r) {
    safeCall |->Bool| {
      Int? c := safeReadChar
      Bool ret := null !== c && r.contains(c)
      if (ret) {
        ++charPos      
      }
      return ret      
    }
  }
  
  override Bool skip() {    
    safeCall |->Bool| {
      Int? c := safeReadChar
      Bool ret := null !== c 
      if (ret) {
        ++charPos
      }
      return ret      
    }
  }
  
  override Bool end() {
    pos := buf.pos
    oldCharPos := charPos
    Bool ret := false
    try {
      Int? c := safeReadChar
      ret = null === c
    } finally {
      buf.seek(pos)
      charPos = oldCharPos
    }
    return ret
  }
  
  private Bool safeCall(Func f) {
    Int oldBytePos := buf.pos
    Int oldCharPos := charPos
    Bool ret := false
    try {
      ret = f()
    } finally {
      if (!ret) {
        buf.seek(oldBytePos)
        charPos := oldCharPos
      }
    }
    return ret
  }

  private Int? safeReadChar() {
    Int? c := null
    if (buf.more) {
      c = buf.readChar        
    }
    return c
  }
}
