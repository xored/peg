
** Block is a part of input which is parsed by some rule.
@Js
const class Block
{

  ** The rule which parsed this block (non-terminal).
  ** It's always a short name (without namespace)
  const Str name

  ** Namespace of the rule which parsed this block (non-terminal).
  ** May be empty.
  const Str namespace

  ** Range of input which occupied by this block.
  const Range range
  
  new make(Str fullName, Range range) {
    i := fullName.index(":")
    if (null == i) {
      this.name = fullName
      this.namespace = ""
    } else {
      this.namespace = fullName[0..<i]
      this.name = fullName[i+1..<fullName.size]
      if (namespace.isEmpty) {
        throw ArgErr("Namespace is empty in this full name: $fullName")
      }
      if (name.isEmpty) {
        throw ArgErr("Name is empty in this full name: $fullName")
      }
    }
    this.range = range
  }
  
  ** Returns full name of the rule, i.e. name with optional namespace separated by colon.
  Str fullName() { namespace.isEmpty ? name : "$namespace:$name" }  
}

** Defines tree structure on blocks.
@Js
mixin BlockNode 
{
  
  abstract Block block()
  
  abstract BlockNode[] kids()
  
}

