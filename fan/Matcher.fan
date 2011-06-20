
@Js
internal mixin Matcher : RuleResolver
{
  ** Tries to match against the given rule. 
  ** If failed, the matcher's state is NOT changed.
  abstract Bool match(Rule rule)
  
  ** Tries to match against the given char. 
  ** If failed, the matcher's state is NOT changed.
  abstract Bool char(Int char)
  
  ** Tries to match against the given string. 
  ** If failed, the matcher's state is NOT changed.
  abstract Bool str(Str str)
  
  ** Tries to match against the given range of chars. 
  ** If failed, the matcher's state is NOT changed.
  abstract Bool range(Range r)
  
  ** Skips one char.  
  ** If failed, the matcher's state is NOT changed.
  abstract Bool skip()
  
  ** Returns true on the end of the input.  
  ** The matcher's state is NOT changed.
  abstract Bool end()
  
  ** Saves the current state of matcher in an internal stack
  abstract Void pushState()
  
  ** Pops state from the internal stack.
  ** If drop is false, the state is applied, so the matcher restores previously
  ** saved state. Otherwise, the state is just dropped.
  abstract Void popState(Bool drop)
  
  Void popRestore() {
    popState(false)
  }
  
  Void popDrop() {
    popState(true)
  }
}
