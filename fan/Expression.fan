
** General parsing expression. 
@Js
internal const class Expression
{
  const Obj? a
  const Obj? b
  
  protected new make(Obj? a, Obj? b) {
    this.a = a
    this.b = b
  }
}

** Empty expression.
@Js
internal const class Empty : Expression {
  static const Empty val := Empty()
  private new make() : super(null, null) {}
}

** Any char (.).
@Js
internal const class Any : Expression {
  static const Any val := Any()
  private new make() : super(null, null) {}
}

** Terminal expression.
@Js
internal const class T : Expression {  
  new make(Str t) : super(t, null) {}  
}

** Non-terminal expression.
@Js
internal const class Nt : Expression {
  new make(Str name) : super(name, null) {}
}

** Sequence expression.
@Js
internal const class Seq : Expression {
  new make(Expression a, Expression b) : super(a, b) {}
}

** Choice expression.
@Js
internal const class Choice : Expression {  
  new make(Expression a, Expression b) : super(a, b) {}
}

** Repetition (e*) expression.
@Js
internal const class Rep : Expression {
  new make(Expression e) : super(e, null) {}
  
  ** Desugar one-or-more expression (e+).
  static Expression plus(Expression e) { Seq(e, Rep(e)) }
}

** Not predicate expression.
@Js
internal const class Not : Expression {
  new make(Expression e) : super(e, null) {}
}

** Expression factory. 
** Use this factory instead of direct expression classes.
@Js
internal const class E {
  
  private new make() {}
  
  ** Empty expression (matches empty input, never fails).
  static Expression empty() { Empty.val }
  
  ** Any char expression (matches any char, fails on EOF).
  static Expression any() { Any.val }
  
  ** Terminal expression.
  static Expression t(Str t) { T(t) }
  
  ** Non-terminal expression.
  static Expression nt(Str name) { Nt(name) }
  
  ** Expression sequence (e1 e2 .. en).
  static Expression seq(Obj[] list) {
    if (2 > list.size) {
      throw ArgErr("Need a list with 2 or more elements, but got $list")
    }
    ret := Seq(parse(list[list.size-2]), parse(list[list.size-1]))
    for (i := list.size-3; i >= 0; --i) {
      ret = Seq(parse(list[i]), ret)
    }
    return ret
  }
  
  ** Prioritized choice of expressions (e1 / e2 / ... / en).
  static Expression choice(Obj[] list) {
    if (2 > list.size) {
      throw ArgErr("Need a list with 2 or more elements, but got $list")
    }
    ret := Choice(parse(list[list.size-2]), parse(list[list.size-1]))
    for (i := list.size-3; i >= 0; --i) {
      ret = Choice(parse(list[i]), ret)
    }
    return ret
  }
  
  ** Character range ([a-z]).
  static Expression range(Range r) { choice(r.toList.map { T(it.toChar) }) }
  
  ** Optional expression (e?).
  static Expression opt(Obj e) { Choice(parse(e), Empty.val) }
  
  ** Zero-or-more repetition (e*).
  static Expression rep(Obj e) { Rep(parse(e)) }
  
  ** One-or-more repetition (e+).
  static Expression rep1(Obj e) { Seq(parse(e), rep(e)) }
  
  ** Not-predicate (!e).
  static Expression not(Obj e) { Not(parse(e)) }
  
  ** And-predicate (&e).
  static Expression and(Obj e) { not(not(e)) }

  ** Syntax sugar for building grammars manually.
  ** 1. If 'e' is an expression, it's returned
  ** 2. If 'e' is a string, 't(e)' is returned
  ** 3. If 'e' is a list, 'seq(e)' is returned
  ** 4. If 'e' is a range, 'range(e)' is returned
  ** 5. Exception thrown otherwise
  private static Expression parse(Obj e) {
    if (e is Expression) {
      return (Expression)e
      
    } else if (e is Str) {
      return t((Str)e)
      
    } else if (e is List) {
      return seq((List)e)
      
    } else if (e is Range) {
      return range((Range)e)
      
    } else {
      throw ArgErr("Invalid argument: type is $e.typeof, value: $e")
    }
  }
}

