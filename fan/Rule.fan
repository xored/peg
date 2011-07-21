
@Js
const class Rule
{
  const Int id
  const Str name
  const Str namespace
  
  internal new make(|This|? f := null) {
    if (null != f) {
      f(this)
    }
  }  
}

@Js
internal enum class Match {
  ** Matched successfully
  success, 
  ** Match failed: wrong text
  fail,
  ** Match failed: not enough text
  lack; 
}