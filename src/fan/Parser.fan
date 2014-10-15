
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

  ** Indents
  private IndentPart[] indents := IndentPart[,]
  ** Indent stack to save indents when under optional or primary clause
  private IndentPart[][] indentStack := IndentPart[][,]
  ** Flag that is set to true once started matching an indent (for the first
  ** time) and is set to false when finished matching the indent. While the
  ** flag is enabled, all the reported non-terminal Blocks are accumulated in
  ** the 'indentBlocks' list to be reported on the following lines.
  private Bool captureIndentBlocks := false
  ** List to accumulate reported Blocks while matching an indent. To be
  ** flushed to 'indents' once the indent is matched.
  private Block[] indentBlocks := [,]

  ** Map, where keys are 'bypePos'es and values are 'charPos'es, which corresponds to indent at begin of line
  private Range:Range skipedRanges := Range:Range[:]
  ** The flag indicates that the last read character is the end of line
  Bool isInEolPos := false

  StreamPos currentPos := StreamPos(0, 0)
  Int:Bool eolPoses := Int:Bool[:]

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
    if(isInEolPos && !indents.isEmpty) {
      skipIndent
    }
    ret := readCharPrivate
    setEolByChar(ret, StreamPos(charPos, bytePos))
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
    if (buf.remaining < size) {
      return null
    }
    try {
      characters := StrBuf()
      size.times { characters.add(readChar.toChar) }
      return characters.toStr
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
    checkCharPosForEol
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
    indentStack.push(indents.dup)
  }
  
  Void handlerApply() {
    if (0 == predicate) {
      handler.apply
    }
    indentStack.pop
  }
  
  Void handlerRollback() {
    if (0 == predicate) {
      handler.rollback
    }
    indents = indentStack.pop
  }
  
  Bool atCurPos(StackRecord r) { bytePos == r.bytePos && charPos == r.charPos }
  
  private Void initStack() {
    push(E.nt(grammar.start))    
  }

  private Int? readCharPrivate() {
    ret := buf.readChar
    if (null != ret) {
      this.bytePos = buf.pos
      this.charPos += 1
    }
    return ret
  }

  private Str currentIndentStr() { indents.map { it.text }.join }

  ** Checks if there is currently expected indentation in the buf
  ** at the current position. Keeps buf position in place.
  Bool isInIndentPos() {
    indentMatched := true

    //save position
    curBytePos := bytePos
    curCharPos := charPos

    indentStr := currentIndentStr

    index := 0
    while(index < indentStr.size) {
      c := readCharPrivate
      if (c != indentStr[index]) {
        indentMatched = false
        break
      }
      ++index
    }
    //restore position
    seek(curBytePos, curCharPos);
    return indentMatched
  }

  ** Consumes currently expected indentation from the buf
  ** and fails if it doesn't match.
  ** When indentation is successfully matched, emits non-terminal blocks
  ** associated with the indentation.
  private Void skipIndent() {
    //save position
    curBytePos := bytePos
    curCharPos := charPos

    indentStr := currentIndentStr

    index := 0
    while(index < indentStr.size) {
      c := readCharPrivate
      if (c != indentStr[index]) {
        match = UnexpectedStr(bytePos, charPos, indentStr[index].toChar, "${c!=null?c.toChar:Str<||>}")
        break
      }
      ++index
    }

    if (MatchState.fail != match.state) {
      emitIndentBlocks
    }

    if(!skipedRanges.containsKey(curBytePos..<bytePos))
      skipedRanges.add(curBytePos..<bytePos, curCharPos..<charPos)
  }

  private Block[] shiftBlocks(Block[] blocks, StreamPos pos) {
    blocks.map {
      BlockImpl(it.name, it.range.offset(pos.char), it.byteRange.offset(pos.byte))
    }
  }

  private StreamPos currentLinePos() { currentPos }

  private Void emitIndentBlocks() {
    blocks := indents.map { shiftBlocks(it.blocks, currentLinePos) }
    blocks.flatten.each { handler.visit(it) }
  }

  ** Returns array which has 2 elements: new 'bytePosRange' and new 'charPosRange'
  Range[] skipIndentRange(Range bytePosRange, Range charPosRange) {
    if(skipedRanges.size==0) //for performance optimization
      return [bytePosRange, charPosRange]
    f := skipedRanges.findAll |v, k| { bytePosRange.start==k.start && bytePosRange.end >= k.end }
    if(f.size==0)
      return [bytePosRange, charPosRange]
    else {
      index := 0
      for(i := 0; i < f.size; i++) {
        if(f.keys[index].end < f.keys[i].end)
          index = i
      }
      bytePosStart := f.keys.get(index).end
      charPosStart := f.vals.get(index).end
      newBytePosRange := bytePosRange.exclusive? bytePosStart..<bytePosRange.end : bytePosStart..bytePosRange.end
      newCharPosRange := charPosRange.exclusive? charPosStart..<charPosRange.end : charPosStart..charPosRange.end
      return [newBytePosRange, newCharPosRange]
    }
  }

  private Void checkCharPosForEol() {
    isInEolPos = eolPoses.containsKey(charPos)
  }

  private Void setEolByChar(Int? character, StreamPos pos) {
    if(character == '\n') {
      isInEolPos = true
      eolPoses.set(pos.char, true)
      currentPos = pos
    }
    else isInEolPos = false
  }
  
  Void pushIndentBlock(Block block) {
    indentBlocks.push(block)
  }

  Void pushIndent() {
    // convert accumulated blocks to offsets from the line beginning
    // to be able to emit them on upcoming lines
    blocks := shiftBlocks(indentBlocks, -currentLinePos)
    indents.push(IndentPart(matchedText, blocks))
  }
  
  Void popIndent() {
    indents.pop
  }

  private Str matchedText() {
    matchedRange := (peek.bytePos + currentIndentStr.size)..<bytePos
    return buf.getRange(matchedRange).readAllStr
  }

  Void startCapturingIndentBlocks() {
    captureIndentBlocks = true
  }

  Void stopCapturingIndentBlocks() {
    captureIndentBlocks = false
    indentBlocks := [,]
  }

  Bool isCapturingIndentBlocks() {
    return captureIndentBlocks
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
