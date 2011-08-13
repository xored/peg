
using printf

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
class Match {
  MatchState state := MatchState.unknown { private set }
  
  Str info := "" {
    private set
    get {
      if (null != args) {
        &info = Format.printf(&info, args)
        args = null
      }
      return &info
    }
  }
  
  Int bytePos := 0 { private set }
  Int charPos := 0 { private set }
  
  private Obj[]? args := null
  
  override Str toStr() {
    if (info.isEmpty) {
      return "$state [byte=$bytePos, char=$charPos]"
    } else {
      return "$state: $info [byte=$bytePos, char=$charPos]"
    }    
  }
  
  internal Void reset() { 
    state = MatchState.unknown 
    info = ""
    args = null
    bytePos = 0
    charPos = 0
  }

  internal Void lack(Int bytePos, Int charPos, Str stopPoint, Obj[]? args := null) { 
    state = MatchState.lack
    info = stopPoint
    this.args = args
    this.bytePos = bytePos
    this.charPos = charPos
  } 
  
  internal Void set(Bool ok, Int bytePos, Int charPos, Str reason := "", Obj[]? args := null) {
    if (ok) {
      state = MatchState.success
      info = ""
    } else {
      state = MatchState.fail
      info = reason
      this.args = args
    }
    this.bytePos = bytePos
    this.charPos = charPos
  }
}