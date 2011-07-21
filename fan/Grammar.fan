
** Grammar is a set of expression associated with non-terminal symbols and the starting expression. 
@Js
internal const mixin Grammar
{
  
  ** Matches non-terminal symbols of the grammar (keys) with corresponding expressions (values).
  abstract Str:Expression rules()
  
  ** Starting expression of the grammar.
  abstract Expression start()
  
}
