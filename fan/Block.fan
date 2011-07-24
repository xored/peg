
** Block is a part of input which is parsed by some rule.
@Js
const mixin Block 
{
  ** The rule which parsed this block (non-terminal). Never empty.
  abstract Str name()
  
  ** Range of input which occupied by this block. May be empty.
  abstract Range range()
}

** Generic implementation of block interface.
@Js
internal const class BlockImpl : Block
{
  override const Str name
  override const Range range
  
  new make(Str name, Range range) {
    if (name.isEmpty) {
      throw ArgErr("Block's name can't be empty")
    }
    this.name = name
    this.range = range
  }
  
  override Str toStr() { "BlockImpl($name, $range)" }
}