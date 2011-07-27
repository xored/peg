
** General parsing expression. 
@Js
const class Expression
{
  const Obj[] kids
  
  protected new make(Obj[] kids := [,]) {
    this.kids = kids
  }
  
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
}

** Any char (.). Has no kids.
// This should be a singleton. 
// But Fantom has troubles with static variables initialization order 
// (at least in JS, http://fantom.org/sidewalk/topic/1381).
@Js
const class Any : Expression {
  new make() : super() {}
  
  override Str toStr() { "." }
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
}

** Non-terminal expression. Has one kid which is a string represents non-terminal symbol. 
@Js
const class Nt : Expression {
  new make(Str name) : super([name]) {}
  
  Str symbol() { (Str)kids.first }
  
  override Str toStr() { "$kids.first" }
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
}

** Repetition (e*) expression. Has one kid, which is an expression to repeat.
@Js
const class Rep : Expression {
  new make(Expression e) : super([e]) {}
  
  override Str toStr() { "${kids.first}*" }
}

** Not-predicate expression. Has one kid which is an expression to check.
@Js
const class Not : Expression {
  new make(Expression e) : super([e]) {}
  
  override Str toStr() { "!$kids.first" }
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
** 4. If 'e' is a range, 'range(e)' is returned
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
