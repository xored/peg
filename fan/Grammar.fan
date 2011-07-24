
** Grammar is a set of expression associated with non-terminal symbols and the starting expression. 
@Js
internal const mixin Grammar
{
  
  ** Matches non-terminal symbols of the grammar (keys) with corresponding expressions (values).
  abstract Str:Expression rules()
  
  ** Non-terminal, which denotes starting expression of the grammar.
  ** 
  ** In the original PEG paper, starting expression may be by its own, without non-terminal.
  ** But this is inconvenient to work with. 
  abstract Str start()
  
}

@Js
internal const class GrammarImpl : Grammar 
{  
  override const Str:Expression rules  
  override const Str start
  
  new make(Str:Expression rules, Str start) {
    this.rules = rules
    this.start = start
  }  
}
