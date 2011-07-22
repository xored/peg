
@Js
internal class StackRecord {
  ** Expression
  const Expression e
  
  ** Current index for container expressions
  Int index := 0
  
  ** Starting position for expressions, which produce blocks
  Int startPos := 0
  
  new make(Expression e) { this.e = e }
  
  override Str toStr() { "{ index=$index, startPos=$startPos, e=$e }" }
}

@Js
class Parser
{
  private Grammar grammar
  
  private StackRecord[] stack := [,]
  
  ** If this >0, we parse under a predicate.  
  private Int predicate := 0
  
  ** If this >0, we parse under an optional clause (choice or repetition).
  private Int optional := 0
  
  Handler handler { private set }
  
  Match match := Match() { private set }
  
  // Fields below is not a part of the parser's state.
  @Transient private Buf? buf
  @Transient private Bool finished := false
  
  internal new make(Grammar grammar, Handler handler) {
    this.grammar = grammar
    this.handler = handler
    push(E.nt(this.grammar.start))
  }
  
  This run(Buf buf, Bool finished := true) {
    this.buf = buf
    this.finished = finished
    
    while (!stack.isEmpty) {
      step

      if (MatchState.lack == match.state) {
        if (this.finished) {
          if (0 == optional) {
            // finished and not under optional state => parsing error
            match.set(false, "Unexpected end of input ($match.info)")
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
  
  ** Assert
  private Void verify(Bool ok, Str msg) {
    if (!ok) {
      throw Err("$msg\nStack:\n$printStack")
    }
  }
  
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
    } else if (r.e is R) {
      this.r
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
    verify(MatchState.unknown == match.state, "Unexpected state for 'empty' expression: $match.state")
    match.set(true)
    pop
  }
  
  ** Handles any-char expression
  private Void any() {
    verify(MatchState.unknown == match.state, "Unexpected state for 'any' expression: $match.state")
    c := buf.readChar
    match.set(null != c, "Expected any char at $buf.pos position, but got EOF")
    pop      
  }
  
  ** Handles terminal symbol
  private Void t() {
    verify(MatchState.unknown == match.state, "Unexpected state for 'terminal' expression: $match.state")
    e := (T)stack.peek.e
    s := (Str)e.kids.first
    if (buf.remaining >= s.toBuf.size) { // need byte size here, not char size
      oldPos := buf.pos
      bufS := buf.readChars(s.size)
      if (bufS != s) {
        buf.seek(oldPos)
      }
      match.set(bufS == s, "Expected string '$s' at pos $buf.pos, but got '$bufS'")
      pop
    } else if (finished) {
      match.set(false, "Expected string '$s' at pos $buf.pos, but got EOF")
      pop
    } else {
      match.lack("terminal $e at $buf.pos position")
    }
  }
  
  ** Handles range
  private Void r() {
    verify(MatchState.unknown == match.state, "Unexpected state for 'range' expression: $match.state")
    r := stack.peek
    if (buf.more) {
      // A char may consist of several bytes.
      // So, if 'buf.more' is 'true', this doesn't guarantee, that buf has one char to read.
      // But we don't handle such situations.
      
      oldPos := buf.pos
      c := buf.readChar
      ok := (r.e.kids.first as Range).contains(c)
      if (!ok) {
        buf.seek(oldPos)
      }
      match.set(ok, "Expected char from range '$r.e' at pos $buf.pos, but got '$c.toChar'")
      pop
    } else if (finished) {
      match.set(false, "Expected char from range '$r.e' at pos $buf.pos, but got EOF")
      pop
    } else {
      match.lack("range $r.e at $buf.pos position")
    }
  }
  
  ** Handles non-terminal symbol
  private Void nt() {
    r := stack.peek
    name := (Str)r.e.kids.first
    
    switch (match.state) {
      case MatchState.unknown:
        // we're here first time
        r.startPos = buf.pos
        newE := grammar.rules[name]
        if (null == newE) {
          match.set(false, "Non-terminal symbol '$name' not found in the grammar")      
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
          handler.visit(Block(name, r.startPos..<buf.pos))
        }
    }    
  }
  
  ** Handles sequence expression
  private Void seq() {
    r := stack.peek
    switch (match.state) {
    case MatchState.unknown:
      // we're here first time
      r.startPos = buf.pos
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
      buf.seek(r.startPos)
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
      r.startPos = buf.pos      
      handler.push
      push(r.e.kids[r.index++])
    
    case MatchState.fail:
      // the last alternative failed, rollback and push the next one (if any) or finish
      handler.rollback
      buf.seek(r.startPos)
      if (r.index < r.e.kids.size) {
        handler.push
        push(r.e.kids[r.index++])
      } else {
        match.set(false, "All alternatives failed in expression $r.e at buf position $r.startPos")
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
        buf.seek(r.startPos)
        if (r.index < r.e.kids.size) {
          handler.push
          push(r.e.kids[r.index++])
        } else {
          match.set(false, "No more input available, and expression $r.e lacked input " + 
            "at buf position $r.startPos")
          pop
        }
      }
      // else does nothing, the will be more input
    }
  }
  
  ** Handles repetition expression
  private Void rep() {
    switch (match.state) {
    case MatchState.unknown:
      // we're here first time
      ++optional
      push(stack.peek.e.kids.first)
      
    case MatchState.success:
      // sub-expression succeeded, push it again
      push(stack.peek.e.kids.first)
      
    case MatchState.fail:
      // sub-expression failed, but it's OK
      match.set(true)
      pop
    
    case MatchState.lack:
      if (finished) {
        // we should do positive match, since there will be no more input
        match.set(true)
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
        r.startPos = buf.pos
        push(stack.peek.e.kids.first)
      
      case MatchState.success:
      case MatchState.fail:
        // sub-expression either failed or succeded. Finalize and reverse match
        buf.seek(r.startPos)
        match.set(MatchState.fail == match.state, "Predicate '$r.e' failed at $r.startPos position")
        pop
    }
  }
}
