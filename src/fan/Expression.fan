
** General parsing expression. 
@Js
const abstract class Expression
{
  const Obj[] kids
  
  new make(Obj[] kids := [,]) {
    this.kids = kids
  }

  ** Performs this expression on the given parser state.
  abstract Void perform(ParserState state)
  
  override Int hash() { kids.hash }
  
  override Bool equals(Obj? other) {
    if (null == other || this.typeof != other.typeof) {
      return false
    }
    o := other as Expression
    // don't just check if kids == o.kids, since it will fail
    // because lists' types difference, which is not what we want
    t := kids.size == o.kids.size
    for (i := 0; t && i < kids.size; ++i) {
      t = kids[i] == o.kids[i]      
    }
    return t
  }
}

** Empty expression. Has no kids.
// This should be a singleton. 
// But Fantom has troubles with static variables initialization order 
// (at least in JS, http://fantom.org/sidewalk/topic/1381).
@Js
const class Empty : Expression {
  new make() : super() {}
  
  override Str toStr() { "empty" }
  
  override Void perform(ParserState state) { state.success }
}

** Any char (.). Has no kids.
// This should be a singleton. 
// But Fantom has troubles with static variables initialization order 
// (at least in JS, http://fantom.org/sidewalk/topic/1381).
@Js
const class Any : Expression {
  new make() : super() {}
  
  override Str toStr() { "." }
  
  override Void perform(ParserState state) {
    c := state.readChar
    if (null == c) {
      state.lack
    } else {
      state.success
    }
  }
}

** Terminal expression. Has one kid, which is a string represents terminal symbol. 
@Js
const class T : Expression {
  new make(Str t) : super([t]) {
    if (t.isEmpty) {
      throw ArgErr("Empty terminal symbol")
    }
  }
  
  Str symbol() { (Str)kids.first }
  
  override Str toStr() { 
    "'" + symbol
      .replace("\\", "\\\\")
      .replace("\t", "\\t")
      .replace("\n", "\\n")
      .replace("\r", "\\r")
      .replace("'", "\\'")
      .replace("\"", "\\\"") + "'"      
  }
  
  override Void perform(ParserState state) {
    r := state.peek
    e := (T)r.e
    s := (Str)e.kids.first
    state.setCurPos(r)
    bufS := state.readChars(s.size)    
    if (null == bufS) {
      // got EOF
      state.seekR(r)
      state.lack
    } else {
      // read something
      if (bufS == s) {
        state.success
      } else {
        state.seekR(r)
        state.error(UnexpectedStr(state.bytePos, state.charPos, s, bufS))
      }
    }    
  }
}

** Class expression. Each kids is a non-empty character range (but can have ranges with 1 element). 
** This is syntax sugar for Choice, but we introduce it as a separate expression,
** because Choice here would be very slow sometimes. 
@Js
const class Class : Expression {
  new make(Range[] ranges) : super(ranges) {
    ranges.each {
      if (it.isEmpty) {
        throw ArgErr("Class can't have empty range $it")
      }
    }
  }
  
  override Str toStr() {
    sb := StrBuf()
    sb.add("[")
    kids.each {
      r := it as Range
      min := r.min
      max := r.max
      sb.add(refine(min.toChar))
      if (min < max) {
        sb.add("-")
        sb.add(refine(max.toChar))
      }
    }
    sb.add("]")
    return sb.toStr
  }
  
  private static Str refine(Str s) {
    s.replace("\\", "\\\\")
      .replace("\t", "\\t")
      .replace("\n", "\\n")
      .replace("\r", "\\r")
      .replace("'", "\\'")
      .replace("\"", "\\\"")
  }
  
  override Void perform(ParserState state) {
    r := state.peek
    state.setCurPos(r)
    c := state.readChar
    if (null == c) {
      // got EOF
      state.seekR(r)
      state.lack
    } else {
      // read something
      rl := r.e.kids as Range[]
      ok := false
      for (i := 0; !ok && i < rl.size; ++i) {
        ok = rl[i].contains(c)
      }
      if (ok) {
        state.success
      } else {
        state.seekR(r)
        state.error(ClassFailed(state.bytePos, state.charPos, r.e, c))
      }
    }
  }
}

** Non-terminal expression. Has one kid which is a string represents non-terminal symbol. 
@Js
const class Nt : Expression {
  new make(Str name) : super([name]) {}
  
  Str symbol() { (Str)kids.first }
  
  override Str toStr() { "$kids.first" }
  
  override Void perform(ParserState state) {
    r := state.peek
    name := (Str)r.e.kids.first    
    switch (state.match.state) {
      case MatchState.unknown:
        // we're here first time
        newE := state.grammar[name]
        if (null == newE) {
          state.error(NotFound(name))
        } else {
          state.setCurPos(r)
          state.push(newE)
        }
      
      case MatchState.fail:
        // sub-expression failed, remove itself and do nothing
        state.pop
      
      case MatchState.success:
        // sub-expression succeeded
        state.pop
        if (0 == state.predicate) {
          // visit block, only if we're not under predicate
          state.handler.visit(BlockImpl(name, r.charPos..<state.charPos))
        }
    }    
  }
}

** Sequence expression. Kids are sub-expressions.
@Js
const class Seq : Expression {
  new make(Expression[] list) : super(list) {
    if (2 > list.size) {
      throw ArgErr("Need a list with 2 or more elements, but got $list")
    }
  }
  
  override Str toStr() {
    b := StrBuf()
    b.add("(")
    kids.each { 
      b.add(it.toStr) 
      b.add(" ")
    }
    b.add(")")
    return b.toStr
  }
  
  override Void perform(ParserState state) {
    r := state.peek
    switch (state.match.state) {
    case MatchState.unknown:
      // we're here first time
      state.setCurPos(r)
      state.push(r.e.kids[r.index++])
    
    case MatchState.success:                
      // sub-expression succeeded, need to push the next one (if any) or finish, propagating the match
      if (r.index < r.e.kids.size) {
        state.push(r.e.kids[r.index++])        
      } else {
        state.pop
      }
    
    case MatchState.fail:      
      // sub-expression failed, need to rollback the buf and stop, propagating the match
      state.seekR(r)
      state.pop
    }
  }
}

** Choice expression. Kids are expressions choices.
@Js
const class Choice : Expression {  
  new make(Expression[] list) : super(list) {
    if (2 > list.size) {
      throw ArgErr("Need a list with 2 or more elements, but got $list")
    }
  }
  
  override Str toStr() {
    b := StrBuf()
    b.add("(")
    kids.each |k, i| { 
      b.add(k.toStr)
      if (i < kids.size-1) {
        b.add(" / ")
      }
    }
    b.add(")")
    return b.toStr
  }
  
  override Void perform(ParserState state) {
    r := state.peek
    switch (state.match.state) {
    case MatchState.unknown:
      // we're here first time, save pos and push the first alternative
      ++state.optional
      state.setCurPos(r)
      state.handlerPush
      state.push(r.e.kids[r.index++])
    
    case MatchState.fail:
      // the last alternative failed, rollback and push the next one (if any) or finish
      state.handlerRollback
      state.seekR(r)
      if (r.index < r.e.kids.size) {
        state.handlerPush
        state.push(r.e.kids[r.index++])
      } else {
        state.error(NoChoice(state.bytePos, state.charPos, (Choice)r.e))
        --state.optional
      }
    
    case MatchState.success:
      // the last alternative succeeded, apply and stop, propagating the match
      state.handlerApply
      state.pop
      --state.optional
    
    case MatchState.lack:
      if (state.finished) {
        // there will be no more input, so continue to push alternatives
        state.handlerRollback
        state.seekR(r)
        if (r.index < r.e.kids.size) {
          state.handlerPush
          state.push(r.e.kids[r.index++])
        } else {
          state.error(NoChoice(state.bytePos, state.charPos, (Choice)r.e))
          --state.optional
        }
      }
      // else does nothing, the will be more input
    }
  }
}

** Repetition (e*) expression. Has one kid, which is an expression to repeat.
@Js
const class Rep : Expression {
  new make(Expression e) : super([e]) {}
  
  override Str toStr() { "${kids.first}*" }
  
  override Void perform(ParserState state) {
    r := state.peek
    switch (state.match.state) {
    case MatchState.unknown:
      // we're here first time
      ++state.optional
      state.setCurPos(r)
      state.handlerPush
      state.push(r.e.kids.first)
      
    case MatchState.success:
      state.handlerApply
      if (state.atCurPos(r)) {
        // sub-expression succeeded, but consumed no input => infinite loop
        state.error(InfiniteLoop(state.bytePos, state.charPos, r.e))
        --state.optional
      } else {
        // remember the pos and push sub-expression again
        state.setCurPos(r)
        state.handlerPush
        state.push(r.e.kids.first)
      }
      
    case MatchState.fail:
      // sub-expression failed, but it's OK
      state.handlerRollback
      state.success
      --state.optional
    
    case MatchState.lack:
      if (state.finished) {
        // we should do positive match, since there will be no more input
        state.handlerRollback
        state.success
        --state.optional
      }
      // else does nothing, the will be more input
    }
  }
}

** Not-predicate expression. Has one kid which is an expression to check.
@Js
const class Not : Expression {
  new make(Expression e) : super([e]) {}
  
  override Str toStr() { "!$kids.first" }
  
  override Void perform(ParserState state) {
    r := state.peek
    switch (state.match.state) {
      case MatchState.unknown:
        // we're here first time. Do initialization and push sub-expression
        ++state.predicate
        state.setCurPos(r)
        state.push(state.peek.e.kids.first)
      
      case MatchState.success:
      case MatchState.fail:
        // sub-expression either failed or succeded. Finalize and reverse match
        state.seekR(r)
        if (state.match.isOk) {
          state.error(PredicateFailed(state.bytePos, state.charPos, r.e))
        } else {
          state.success
        }
        --state.predicate
    }
  }
}

** Expression factory. 
** Use this factory instead of direct expression classes.
** 
** Some syntax sugar for building grammars manually is applied. Each 'Obj e', passed to methods
** directly or as a part of list, is treated as follows: 
** 
** 1. If 'e' is an expression, it's returned
** 2. If 'e' is a string, ... 
**    2.1. ...and it starts with # and it's not just "#", 'nt(e without #)' is returned
**    2.2. 't(e)' is returned otherwise (so, terminals which start with #, must be specified explicitly)
** 3. If 'e' is a list, 'seq(e)' is returned
** 4. If 'e' is a range, 'clazz(e)' is returned
** 5. Exception is thrown otherwise
@Js
const class E {
  
  private new make() {}
  
  ** Empty expression (matches empty input, never fails).
  static Expression empty() { Empty() }
  
  ** Any char expression (matches any char, fails on EOF).
  static Expression any() { Any() }
  
  ** Terminal expression.
  static Expression t(Str t) { T(t) }
  
  ** Non-terminal expression.
  static Expression nt(Str name) { Nt(name) }
  
  ** Expression sequence (e1 e2 .. en).
  static Expression seq(Obj[] list) { Seq(list.map { parse(it) }) }
  
  ** Prioritized choice of expressions (e1 / e2 / ... / en).
  static Expression choice(Obj[] list) { Choice(list.map { parse(it) }) }
  
  ** Character class ([a-z]).
  static Expression clazz(Obj[] ranges) {
    rl := Range[,]
    ranges.each {
      if (it is Range) {
        rl.add((Range)it)
      } else if (it is Int) {
        i := it as Int
        rl.add(i..i)
      } else {
        throw ArgErr("Expected Int or Range, but got $it.typeof: $it")
      }
    }
    return Class(rl)    
  }
  
  ** Optional expression (e?).
  static Expression opt(Obj e) { Choice([parse(e), Empty()]) }
  
  ** Zero-or-more repetition (e*).
  static Expression rep(Obj e) { Rep(parse(e)) }
  
  ** One-or-more repetition (e+).
  static Expression rep1(Obj e) { Seq([parse(e), rep(e)]) }
  
  ** Not-predicate (!e).
  static Expression not(Obj e) { Not(parse(e)) }
  
  ** And-predicate (&e).
  static Expression and(Obj e) { not(not(e)) }

  private static Expression parse(Obj e) {
    if (e is Expression) {
      return (Expression)e
      
    } else if (e is Str) {
      s := e as Str
      return s.startsWith("#") && 1 < s.size ? nt(s[1..<s.size]) : t(s) 
      
    } else if (e is List) {
      return seq((List)e)
      
    } else if (e is Range) {
      return clazz([e as Range])
      
    } else {
      throw ArgErr("Invalid argument: type is $e.typeof, value: $e")
    }
  }
}
