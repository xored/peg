
** Main class, allows to parse inputs using given grammars.
** A separate instance of this class is intended to be used for parsing a single input.
** It's recommended to use static parsing methods, unless you need stream parsing. 
@Js
class Parser
{
  private ParserState state
  
  ** Grammar the parser works with
  Grammar grammar { private set }
  
  ** Handler the parser works with
  Handler handler { private set }
  
  ** Current match state
  Match match() { state.match }
 
  // Fields below is not a part of the parser's state.
  @Transient internal Buf? buf0
  @Transient internal Bool finished := false

  ** Parses the given input with the given grammar.
  ** Returns the root node of the parsed tree.
  ** If parsing fails, ParseErr is thrown.
  static BlockNode tree(Grammar g, Buf in) { BlockNodeImpl.fromList(list(g, in)) }
  
  ** Parses the given input with the given grammar.
  ** Returns parsed blocks list.
  ** If parsing fails, ParseErr is thrown.
  static Block[] list(Grammar g, Buf in) {
    lh := ListHandler()
    p := Parser(g, lh).run(in)
    if (MatchState.success != p.match.state) {
      throw ParseErr("Failed to parse input: $p.match")
    }
    return lh.blocks
  }
  
  ** Parses the given input with the given grammar and handler.
  ** Returns match.
  static Match parse(Grammar g, Buf in, Handler h) { Parser(g, h).run(in).match }

  ** Creates a parser for the given grammar and handler. 
  new make(Grammar grammar, Handler handler) {
    this.grammar = grammar
    this.handler = handler
    state = ParserState(this)
  }
  
  ** Parses the given buffer. Returns this instance of the parser.
  ** 
  ** If the current match is fatal, returns immediately.
  ** 
  ** If 'finished' is 'false', stream parsing mode is activated. You may call this method several times with 'finished=false',
  ** but the last time you call it 'finished' should be 'true'. Otherwise, results will be unreliable.
  ** When you call this method several times with 'finished=false', the 'buf' passed to Nth call
  ** should contain the 'buf' passed to call N-1. I.e. if you have a string 'abcd' and want to parse it in chunks, 
  ** you should do the following:
  ** pre>
  ** p.run("a".toBuf, false)
  ** p.run("ab".toBuf, false)
  ** p.run("abc".toBuf, false)
  ** p.run("abcd".toBuf, true)
  ** <pre 
  This run(Buf buf, Bool finished := true) {
    if (state.match.isFatal) {
      // do nothing with a fatal match
      return this
    }
    if (state.stack.isEmpty) {
      // nothing to be done, must not change anything
      return this
    }
    this.buf0 = buf
    try {
      this.finished = finished    
      // restore working state
      state.match = Match.unknown
      state.seek(state.bytePos, state.charPos)    
      while (!state.match.isFatal && !state.stack.isEmpty) {
        state.peek.e.perform(state)
        if (MatchState.lack == match.state) {
          if (this.finished) {
            if (0 == state.optional) {
              // finished and not under optional state => parsing error
              state.match = EofMatch(state.bytePos, state.charPos, match)
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
    } finally {
      this.buf0 = null
    }
  }
  
}

@Js
class ParserState {
  ** Current match state
  Match match := Match.unknown
  
  StackRecord[] stack := StackRecord[,] { capacity = 100 }
  
  ** If this >0, we parse under a predicate.  
  Int predicate := 0
  
  ** If this >0, we parse under an optional clause (choice or repetition).
  Int optional := 0
  
  ** Current position in the buffer.
  Int charPos := 0
  Int bytePos := 0

  private Parser parser

  internal new make(Parser parser) {
    this.parser = parser
    initStack
  } 

  ** Grammar the parser works with
  Grammar grammar() { parser.grammar }
  
  ** Handler the parser works with
  Handler handler() { parser.handler }
  
  Buf buf() { parser.buf0 }
  
  Bool finished() { parser.finished }
  
  StackRecord peek() { stack.peek }
  
  Void pop() { stack.pop }  
  
  Int? readChar() {
    ret := buf.readChar
    if (null != ret) {
      this.bytePos = buf.pos
      this.charPos += 1
    }
    return ret
  }
  
  Void lack(Expression? e := null) {
    m := LackMatch(bytePos, charPos, null == e ? stack.peek.e : e)
    if (finished) {
      match = EofMatch(bytePos, charPos, m)
      pop
    } else {
      match = m
    }
  }
  
  Void success() { 
    match = Match.success 
    pop
  }
  
  Void setCurPos(StackRecord r) {
    r.bytePos = bytePos
    r.charPos = charPos
  }
  
  Str? readChars(Int size) {
    try {
      if (buf.remaining < size) {
        lastChars := buf.readChars(buf.remaining)
        return lastChars // caller will define what to do with that (lack or fail state)
      }

      ret := buf.readChars(size)
      this.bytePos = buf.pos
      this.charPos += ret.size
      return ret      
    } catch (Err e) {
      // unexpected eof
      return null
    }
  }
  
  Void seekR(StackRecord r) { seek(r.bytePos, r.charPos) }
  
  Void seek(Int bytePos, Int charPos) {
    buf.seek(bytePos)
    this.charPos = charPos
    this.bytePos = bytePos
  }
  
  Void error(Match m) {
    match = m
    pop
  }
  
  Void push(Expression e) {
    match = Match.unknown
    stack.push(StackRecord(e))
  }
  
  Void handlerPush() {
    if (0 == predicate) {
      handler.push
    }
  }
  
  Void handlerApply() {
    if (0 == predicate) {
      handler.apply
    }
  }
  
  Void handlerRollback() {
    if (0 == predicate) {
      handler.rollback
    }
  }
  
  Bool atCurPos(StackRecord r) { bytePos == r.bytePos && charPos == r.charPos }
  
  private Void initStack() {
    push(E.nt(grammar.start))    
  }
}

@Js
class StackRecord {
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

@Js
const class IndentPart {
  const Str text
  const Block[] blocks

  new make(Str text, Block[] blocks) {
    this.text = text
    this.blocks = blocks
  }
}

@Js
const class StreamPos {
  const Int char
  const Int byte

  new make(Int char, Int byte) {
    this.char = char
    this.byte = byte
  }

  @Operator StreamPos negate() {
    StreamPos(-char, -byte)
  }
}
