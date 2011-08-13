
@Js
internal class StackRecord {
  ** Expression
  const Expression e
  
  ** Current index for container expressions
  Int index := 0
  
  ** Position for expressions, which produce blocks
  Int charPos := 0
  Int bytePos := 0
  
  new make(Expression e) { this.e = e }
  
  override Str toStr() { "{ index=$index, charPos=$charPos, bytePos=$bytePos e=$e }" }
}

** Main class, allows to parse inputs using given grammars.
** 
** Please note, that before version 1.0 every non-static public slots of this class
** are the subject to change. If you want to ensure your code will be compatible
** with later versions, use static part of the API only. 
@Js
class Parser
{
  private Grammar grammar
  
  private StackRecord[] stack := [,]
  
  ** If this >0, we parse under a predicate.  
  private Int predicate := 0
  
  ** If this >0, we parse under an optional clause (choice or repetition).
  private Int optional := 0
  
  ** Current position in the buffer.
  private Int charPos := 0
  private Int bytePos := 0
  
  Handler handler { private set }
  
  Match match := Match() { private set }
  
  // Fields below is not a part of the parser's state.
  @Transient private Buf? buf0
  @Transient private Bool finished := false
  
  ** Parses the given input with the given grammar.
  ** Returns the root node of the parsed tree.
  ** If parsing fails, ParseErr is thrown.
  static BlockNode tree(Grammar g, Buf in) {
    lh := ListHandler()
    p := Parser(g, lh).run(in)
    if (MatchState.success != p.match.state) {
      throw ParseErr("Failed to parse input: $p.match")
    }
    ret := BlockNodeImpl.fromList(lh.blocks)
    return ret
  }
  
  new make(Grammar grammar, Handler handler) {
    this.grammar = grammar
    this.handler = handler
    push(E.nt(this.grammar.start))
  }
  
  private Void mSet(Bool ok, Str reason := "", Obj[]? args := null, StackRecord? r := null) {
    if (null == r) {
      match.set(ok, bytePos, charPos, reason, args)
    } else {
      match.set(ok, r.bytePos, r.charPos, reason, args)
    }
  }
  
  private Void mLack(Str stopPoint, Obj[]? args := null, StackRecord? r := null) {
    if (null == r) {
      match.lack(bytePos, charPos, stopPoint, args)
    } else {
      match.lack(r.bytePos, r.charPos, stopPoint, args)
    }
  }
  
  private Int? readChar() {
    ret := buf0.readChar
    if (null != ret) {
      this.bytePos = buf0.pos
      this.charPos += 1
    }
    return ret
  }
  
  private Str? readChars(Int size) {
    try {
      ret := buf0.readChars(size)      
      this.bytePos = buf0.pos
      this.charPos += ret.size
      return ret
    } catch (IOErr e) {
      // unexpected eof
      return null
    }
  }
  
  private Void seek(Int bytePos, Int charPos) {
    buf0.seek(bytePos)
    this.charPos = charPos
    this.bytePos = bytePos
  }
  
  private Void seekR(StackRecord r) { seek(r.bytePos, r.charPos) }
  
  private Void setCurPos(StackRecord r) {
    r.bytePos = bytePos
    r.charPos = charPos
  }
  
  This run(Buf buf, Bool finished := true) {
    if (stack.isEmpty) {
      // nothing to be done, must not change anything
      return this
    }    
    this.buf0 = buf
    this.finished = finished    
    // restore working state
    match.reset
    seek(bytePos, charPos)    
    while (!stack.isEmpty) {
      step
      if (MatchState.lack == match.state) {
        if (this.finished) {
          if (0 == optional) {
            // finished and not under optional state => parsing error
            mSet(false, "Unexpected end of input (%s)", [match.info])
            break
          }
          // finished and under optional state => can do more, continue
        } else {
          // not finished -- stop this step regardless of optional state
          break
        }
      } // lack state
    } // while loop    
    return this
  }
  
  internal Expression[] expressionStack() { stack.map { it.e } }
  
  private Str printStack() {
    ret := StrBuf()
    stack.eachr { 
      ret.add(it) 
      ret.add("\n")
    }
    return ret.toStr
  }
  
  private Void step() {
    r := stack.peek
    if (r.e is Empty) {
      empty
    } else if (r.e is Any) {
      any
    } else if (r.e is T) {
      t
    } else if (r.e is Class) {
      clazz
    } else if (r.e is Nt) {
      nt
    } else if (r.e is Seq) {
      seq
    } else if (r.e is Choice) {
      choice
    } else if (r.e is Rep) {
      rep
    } else if (r.e is Not) {
      not
    } else {
      throw Err("Internal error: unknown expression type: $r.e.typeof, expression: $r.e")
    }
  }
  
  private Void push(Expression e) {
    match.reset
    stack.push(StackRecord(e))
  }
  
  private Void pop() {
    r := stack.pop
    if (r.e is Choice || r.e is Rep) {
      --optional
    } else if (r.e is Not) {
      --predicate
    }
  }
  
  ** Handles empty expression
  private Void empty() {
    mSet(true)
    pop
  }
  
  ** Handles any-char expression
  private Void any() {
    c := readChar
    mSet(null != c, "Expected any char, but got EOF")
    pop      
  }
  
  ** Handles terminal symbol
  private Void t() {
    r := stack.peek
    e := (T)r.e
    s := (Str)e.kids.first
    setCurPos(r)
    bufS := readChars(s.size)    
    if (null == bufS) {
      // got EOF
      seekR(r)
      if (finished) {
        mSet(false, "Expected string '%s', but got EOF", [s])
        pop
      } else {
        mLack("terminal %s", [e])
      }
    } else {
      // read something
      if (bufS != s) {
        seekR(r)
      }
      mSet(bufS == s, "Expected string '%s', but got '%s'", [s, bufS])
      pop
    }    
  }
  
  ** handles class
  private Void clazz() {
    r := stack.peek
    setCurPos(r)
    c := readChar
    if (null == c) {
      // got EOF
      seekR(r)
      if (finished) {
        mSet(false, "Expected char from class '%s', but got EOF", [r.e])
        pop
      } else {
        mLack("class %s", [r.e])
      }
    } else {
      // read something
      rl := r.e.kids as Range[]
      ok := false
      for (i := 0; !ok && i < rl.size; ++i) {
        ok = rl[i].contains(c)
      }
      if (!ok) {
        seekR(r)
      }
      mSet(ok, "Expected char from class '%s', but got '%c'", [r.e, c])
      pop
    }
  }
  
  ** Handles non-terminal symbol
  private Void nt() {
    r := stack.peek
    name := (Str)r.e.kids.first
    
    switch (match.state) {
      case MatchState.unknown:
        // we're here first time
        setCurPos(r)
        newE := grammar[name]
        if (null == newE) {
          mSet(false, "Non-terminal symbol '%s' not found in the grammar", [name])
        } else {
          push(newE)
        }
      
      case MatchState.fail:
        // sub-expression failed, remove itself and do nothing
        pop
      
      case MatchState.success:
        // sub-expression succeeded
        pop
        if (0 == predicate) {
          // visit block, only if we're not under predicate
          handler.visit(BlockImpl(name, r.charPos..<charPos))
        }
    }    
  }
  
  ** Handles sequence expression
  private Void seq() {
    r := stack.peek
    switch (match.state) {
    case MatchState.unknown:
      // we're here first time
      setCurPos(r)
      push(r.e.kids[r.index++])
    
    case MatchState.success:                
      // sub-expression succeeded, need to push the next one (if any) or finish, propagating the match
      if (r.index < r.e.kids.size) {
        push(r.e.kids[r.index++])        
      } else {
        pop        
      }
    
    case MatchState.fail:      
      // sub-expression failed, need to rollback the buf and stop, propagating the match
      seekR(r)
      pop
    }
  }
  
  ** Handles choice expression
  private Void choice() {
    r := stack.peek
    switch (match.state) {
    case MatchState.unknown:
      // we're here first time, save pos and push the first alternative
      ++optional
      setCurPos(r)
      handler.push
      push(r.e.kids[r.index++])
    
    case MatchState.fail:
      // the last alternative failed, rollback and push the next one (if any) or finish
      handler.rollback
      seekR(r)
      if (r.index < r.e.kids.size) {
        handler.push
        push(r.e.kids[r.index++])
      } else {
        mSet(false, "All alternatives failed in expression %s", [r.e], r)
        pop
      }
    
    case MatchState.success:
      // the last alternative succeeded, apply and stop, propagating the match
      handler.apply
      pop
    
    case MatchState.lack:
      if (finished) {
        // there will be no more input, so continue to push alternatives
        handler.rollback
        seekR(r)
        if (r.index < r.e.kids.size) {
          handler.push
          push(r.e.kids[r.index++])
        } else {
          mSet(false, "No more input available, and expression %s lacks input", [r.e], r)
          pop
        }
      }
      // else does nothing, the will be more input
    }
  }
  
  private Bool atCurPos(StackRecord r) { bytePos == r.bytePos && charPos == r.charPos }
  
  ** Handles repetition expression
  private Void rep() {
    r := stack.peek
    switch (match.state) {
    case MatchState.unknown:
      // we're here first time
      ++optional
      setCurPos(r)
      push(r.e.kids.first)
      
    case MatchState.success:
      if (atCurPos(r)) {
        // sub-expression succeeded, but consumed no input => infinite loop
        mSet(false, "Inifnite loop, expression: %s", [r.e])
        pop
      } else {
        // remember the pos and push sub-expression again
        setCurPos(r)
        push(r.e.kids.first)
      }
      
    case MatchState.fail:
      // sub-expression failed, but it's OK
      mSet(true)
      pop
    
    case MatchState.lack:
      if (finished) {
        // we should do positive match, since there will be no more input
        mSet(true)
        pop
      }
      // else does nothing, the will be more input
    }
  }
  
  ** Handles not-predicate expression
  private Void not() {
    r := stack.peek
    switch (match.state) {
      case MatchState.unknown:
        // we're here first time. Do initialization and push sub-expression
        ++predicate
        setCurPos(r)
        push(stack.peek.e.kids.first)
      
      case MatchState.success:
      case MatchState.fail:
        // sub-expression either failed or succeded. Finalize and reverse match
        seekR(r)
        mSet(MatchState.fail == match.state, "Predicate '%s' failed", [r.e], r)
        pop
    }
  }
}
