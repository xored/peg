
@Js
enum class MatchState {
  unknown,  
  ** Matched successfully
  success, 
  ** Match failed: wrong text
  fail,
  ** Match failed: not enough text
  lack;
}

@Js
const class Match {
  static const Match unknown := Match(MatchState.unknown, 0, 0)
  static const Match success := Match(MatchState.success, 0, 0)
  
  const MatchState state
  const Int bytePos
  const Int charPos
  const Match? cause
  
  new make(MatchState state, Int bytePos, Int charPos, Match? cause := null) {
    this.state = state
    this.bytePos = bytePos
    this.charPos = charPos
    this.cause = cause
  }
  
  Bool isOk() { MatchState.success == state }
  
  virtual protected Str explanation() { "" }
  
  override Str toStr() { 
    s := "$state: $explanation [byte=$bytePos, char=$charPos]"
    if (null != cause) {
      s += "\nCause: $cause"
    }
    return s
  }
}

@Js
const class EofMatch : Match {
  new make(Int bytePos, Int charPos, Match? cause := null) : super(MatchState.fail, bytePos, charPos, cause) {}
  override protected Str explanation() { "unexpected end of input" }
}

@Js
const class LackMatch : Match {
  private const Expression e
  new make(Int bytePos, Int charPos, Expression e) : super(MatchState.lack, bytePos, charPos) { this.e = e }
  override protected Str explanation() { "lack input for $e" }
}

@Js
const class UnexpectedStr : Match {
  private const Str expected
  private const Str got
  new make(Int bytePos, Int charPos, Str expected, Str got) : super(MatchState.fail, bytePos, charPos) {
    this.expected = expected
    this.got = got
  }
  override protected Str explanation() { "expected $expected, but got $got" }
}

@Js
const class ClassFailed : Match {
  private const Class clazz
  private const Int got
  new make(Int bytePos, Int charPos, Class clazz, Int got) : super(MatchState.fail, bytePos, charPos) {
    this.clazz = clazz
    this.got = got
  }
  override protected Str explanation() { "expected $clazz, but got $got" }
}

@Js
const class NotFound : Match {
  private const Str symbol
  new make(Str symbol) : super(MatchState.fail, 0, 0) { this.symbol = symbol }
  override protected Str explanation() { "Non-terminal symbol '$symbol' not found in the grammar" }
}
  
@Js
const class NoChoice : Match {
  private const Choice e
  new make(Int bytePos, Int charPos, Choice e) : super(MatchState.fail, bytePos, charPos) { this.e = e }
  override protected Str explanation() { "All alternatives failed in expression $e" }
}
  
@Js
const class InfiniteLoop : Match {
  private const Rep e
  new make(Int bytePos, Int charPos, Rep e) : super(MatchState.fail, bytePos, charPos) { this.e = e }
  override protected Str explanation() { "Inifnite loop, expression: $e" }
}

@Js
const class PredicateFailed : Match {
  private const Not e
  new make(Int bytePos, Int charPos, Not e) : super(MatchState.fail, bytePos, charPos) { this.e = e }
  override protected Str explanation() { "Predicate failed: $e" }
}
