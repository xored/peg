
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
  Str info := "" { private set }
  
  override Str toStr() {
    if (info.isEmpty) {
      return "$state"
    } else {
      return "$state: $info"
    }    
  }
  
  internal Void reset() { 
    state = MatchState.unknown 
    info = ""
  }

  internal Void lack(Str stopPoint) { 
    state = MatchState.lack
    info = stopPoint
  } 
  
  internal Void set(Bool ok, Str reason := "") {
    if (ok) {
      state = MatchState.success
      info = ""
    } else {
      state = MatchState.fail
      info = reason
    }
  }
}