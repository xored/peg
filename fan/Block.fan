
** Block is a part of input which is parsed by some rule.
@Js
mixin Block
{

  ** The rule which parsed this block (non-terminal).
  ** It's always a short name (without namespace)
  abstract Str name

  ** Namespace of the rule which parsed this block (non-terminal).
  ** May be empty.
  abstract Str namespace

  ** Range of input which occupied by this block.
  abstract Range range
  
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