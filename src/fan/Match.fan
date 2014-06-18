
** Parser state 
@Js
enum class MatchState {
  
  ** State before the parsing process is started
  unknown,
  
  ** Matched successfully. For stream parsing this is meaningful only when the stream is finished.
  ** I.e. matching the first chunk of input may be successful, but overall match may still fail, when 
  ** the other chunks are come. 
  success, 
  
  ** Match failed: wrong text. This means that input does not conform to the grammar.
  fail,
  
  ** Match failed: not enough text. For stream parsing, this means that parser reached current end of input
  ** and waiting for more input. 
  lack,
  
  ** Match failed beyond recovery. Usually, this means errors in grammar. 
  ** After getting this state, subsequent Parser.run() calls will immediately return with this state.
  fatal;
}

** Describes parser state with some additional information. 
** Not all states has additional info, and some sub-classes has more fields.
@Js
const class Match {
  static const Match unknown := Match(MatchState.unknown, 0, 0)
  static const Match success := Match(MatchState.success, 0, 0)

  ** Parser state
  const MatchState state
  
  ** Offset from the beginning of input in bytes
  const Int bytePos
  
  ** Offset from the beginning of input in characters
  const Int charPos
  
  ** Optional cause of this match
  const Match? cause
  
  new make(MatchState state, Int bytePos, Int charPos, Match? cause := null) {
    this.state = state
    this.bytePos = bytePos
    this.charPos = charPos
    this.cause = cause
  }

  Bool isOk() { MatchState.success == state }
  
  Bool isFatal() { MatchState.fatal == state }
  
  virtual protected Str explanation() { "" }
  
  override Str toStr() { 
    s := "$state: $explanation [byte=$bytePos, char=$charPos]"
    if (null != cause) {
      s += "\nCause: $cause"
    }
    return s
  }
}

// Ordinary matches -----------------------------------------------------------

** Failed match: unexpected end of input.
@Js
const class EofMatch : Match {
  new make(Int bytePos, Int charPos, Match? cause := null) : super(MatchState.fail, bytePos, charPos, cause) {}
  override protected Str explanation() { "unexpected end of input" }
}

** Lack match (meaningful for stream parsing).
@Js
const class LackMatch : Match {
  const Expression e
  new make(Int bytePos, Int charPos, Expression e) : super(MatchState.lack, bytePos, charPos) { this.e = e }
  override protected Str explanation() { "lack input for $e" }
}

** Failed match: unexpected input. Usually this means that input does not conform to grammar 
@Js
const class UnexpectedStr : Match {
  
  ** What input was expected
  const Str expected
  
  ** What we actually got
  const Str got
  
  new make(Int bytePos, Int charPos, Str expected, Str got) : super(MatchState.fail, bytePos, charPos) {
    this.expected = expected
    this.got = got
  }
  override protected Str explanation() { "expected $expected, but got $got" }
}

** Failed match: unexpected character in input while we expected a character from the given class.
@Js
const class ClassFailed : Match {
  
  ** Class of characters. On of them was expected. 
  const Class clazz
  
  ** Character we actually got
  const Int got
  
  new make(Int bytePos, Int charPos, Class clazz, Int got) : super(MatchState.fail, bytePos, charPos) {
    this.clazz = clazz
    this.got = got
  }
  override protected Str explanation() { "expected $clazz, but got $got" }
}

** Failed match: we checked all alternatives of Choice expression, and each one is failed.
@Js
const class NoChoice : Match {
  
  ** Choice expression that is failed. 
  const Choice e
  
  new make(Int bytePos, Int charPos, Choice e) : super(MatchState.fail, bytePos, charPos) { this.e = e }
  override protected Str explanation() { "All alternatives failed in expression $e" }
}

** Failed match: we checked the expression under NOT predicate and it matched (therefore, the predicate failed).
@Js
const class PredicateFailed : Match {
  
  ** Predicate that failed
  const Not e
  
  new make(Int bytePos, Int charPos, Not e) : super(MatchState.fail, bytePos, charPos) { this.e = e }
  override protected Str explanation() { "Predicate failed: $e" }
}

// Fatal matches --------------------------------------------------------------

** Fatal match: non-terminal symbol definition is not found in grammar.
@Js
const class NotFound : Match {
  
  ** Symbol that is not found.
  const Str symbol
  
  new make(Str symbol) : super(MatchState.fatal, 0, 0) { this.symbol = symbol }
  override protected Str explanation() { "Non-terminal symbol (rule) '$symbol' not found in the grammar" }
}

** fatal match: grammar has an infinite loop, and parser reached it. 
@Js
const class InfiniteLoop : Match {
  
  ** Expression that caused infinite loop.
  const Rep e
  
  new make(Int bytePos, Int charPos, Rep e) : super(MatchState.fatal, bytePos, charPos) { this.e = e }
  override protected Str explanation() { "Infinite loop, expression: $e" }
}

