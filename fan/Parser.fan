
@Js
internal class StackRecord {
  ** Expression
  const Expression e
  
  ** Current index for container expressions
  Int index := 0
  
  ** Starting position for expressions, which produce blocks
  Int startPos := 0
  
  new make(Expression e) { this.e = e }
}

@Js
class Parser
{
  private Grammar grammar
  private Handler handler
  
  private StackRecord[] stack := [,]
  
  ** If this >0, we parse under a predicate.  
  private Int predicate := 0
  
  Match match := Match() { private set }
  
  internal new make(Grammar grammar, Handler handler) {
    this.grammar = grammar
    this.handler = handler
    stack.push(StackRecord(this.grammar.start))
  }
  
  Void run(Buf buf, Bool finished := true) {
    while (MatchState.fail != match.state && MatchState.lack != match.state && !stack.isEmpty) {
      step(buf, finished)
    }
    if (MatchState.lack == match.state && finished) {
      match.set(false, "Unexpected end of input ($match.info)")
    }
  }
  
  Void finish(Buf buf) {}

  ** Assert
  private Void verify(Bool ok, Str msg) {
    if (!ok) {
      throw Err(msg)
    }
  }
  
  private Void step(Buf buf, Bool finished) {
    r := stack.peek
    if (r.e is Empty) {
      empty
    } else if (r.e is Any) {
      any(buf)
    } else if (r.e is T) {
      t(buf)
    } else if (r.e is Nt) {
      nt(buf)
    } else if (r.e is Seq) {
      seq
    } else if (r.e is Choice) {
      choice(buf, finished)
    } else if (r.e is Rep) {
      rep(finished)
    } else if (r.e is Not) {
      not(buf)
    } else {
      throw Err("Internal error: unknown expression type: $r.e.typeof, expression: $r.e")
    }
  }
  
  ** Handles empty expression
  private Void empty() {
    verify(MatchState.unknown == match.state, "Unexpected state for 'empty' expression: $match.state")
    match.set(true)
    stack.pop
  }
  
  ** Handles any-char expression
  private Void any(Buf buf) {
    verify(MatchState.unknown == match.state, "Unexpected state for 'any' expression: $match.state")
    c := buf.readChar
    if (null == c) {
      match.lack("'.' at $buf.pos position")
    } else {
      match.set(true)
      stack.pop      
    }
  }
  
  ** Handles terminal symbol
  private Void t(Buf buf) {
    verify(MatchState.unknown == match.state, "Unexpected state for 'terminal' expression: $match.state")
    e := (T)stack.peek.e
    s := (Str)e.kids.first
    if (buf.remaining < s.size) {
      match.lack("terminal '$e' at $buf.pos position")
    } else {
      oldPos := buf.pos
      bufS := buf.readChars(s.size)
      if (bufS != s) {
        buf.seek(oldPos)
      }
      match.set(bufS == s, "Expected string '$s' at pos $buf.pos, but got '$bufS'")
      stack.pop
    }
  }
  
  ** Handles non-terminal symbol
  private Void nt(Buf buf) {
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
          stack.push(StackRecord(newE))
        }
      
      case MatchState.fail:
        // sub-expression failed, remove itself and do nothing
        stack.pop
      
      case MatchState.success:
        // sub-expression succeeded
        stack.pop
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
      case MatchState.success:
        // we're here first time, or sub-expression succeeded.
        if (r.index < r.e.kids.size) {
          // if we have more sub-expressions, push the next one
          match.reset
          stack.push(StackRecord(r.e.kids[r.index++]))        
        } else {
          // we're out of sub-expressions, remove the expression and propagate match
          stack.pop        
        }
      
      case MatchState.fail:
        // sub-expression failed, remove the expression and propagate match
        stack.pop
    }
  }
  
  ** Handles choice expression
  private Void choice(Buf buf, Bool finished) {
    r := stack.peek
    pushNext := true
    switch (match.state) {
    case MatchState.unknown:
      // we're here first time
      r.startPos = buf.pos
      handler.push          
    
    case MatchState.fail:
      // the last alternative failed, rollback
      handler.rollback
      buf.seek(r.startPos)
    
    case MatchState.success:
      // the last alternative succeeded, apply
      handler.apply
      stack.pop
      pushNext = false
    
    case MatchState.lack:
      if (finished) {
        // there will be no more input, so continue to push alternatives
        handler.apply
        stack.pop
      } else {
        // does nothing, since there will be more input
        pushNext = false          
      }
    }
    if (pushNext) {
      if (r.index < r.e.kids.size) {
        // we have non-checked alternative
        match.reset
        stack.push(StackRecord(r.e.kids[r.index++]))        
      } else {
        // we checked all the alternatives. Remove the expression and propagate existing match
        stack.pop
      }            
    }
  }
  
  ** Handles repetition expression
  private Void rep(Bool finished) {
    switch (match.state) {
    case MatchState.unknown:
    case MatchState.success:
      // we're here first time, or sub-expression succeeded. Push sub-expression (again)
      stack.push(StackRecord(stack.peek.e.kids.first))
      
    case MatchState.fail:
      // sub-expression failed, but it's ok
      match.set(true)
      stack.pop
    
    case MatchState.lack:
      if (finished) {
        // we should do positive match, since there will be no more input
        match.set(true)
        stack.pop
      }
    }
  }
  
  ** Handles not-predicate expression
  private Void not(Buf buf) {
    r := stack.peek
    switch (match.state) {
      case MatchState.unknown:
        // we're here first time. Do initialization and push sub-expression
        ++predicate
        r.startPos = buf.pos
        stack.push(StackRecord(stack.peek.e.kids.first))
      
      case MatchState.success:
      case MatchState.fail:
        // sub-expression either failed or succeded. Finalize and reverse match
        --predicate
        buf.seek(r.startPos)
        match.set(MatchState.fail == match.state, "Predicate '$r.e' failed at $r.startPos position")
        stack.pop
    }
  }
}
