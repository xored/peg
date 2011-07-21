
@Js
class Parser
{
  private Handler handler
  
  private Bool match := true  
  private Bool eoi := false // end of input
  
  //private Grammar grammar
  private Expression[] stack := [,]
  
  new make(Str grammar, Handler handler) {
    this.handler = handler
  }
  
  Void run(Buf buf) {
    
  }
  
  Void finish(Buf buf) {}
  
}
