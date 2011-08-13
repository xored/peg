
using peg
using util

class FileExample : AbstractMain
{
  @Arg { help="grammar text file" }
  File? g
  
  @Arg { help="input file" }
  File? in
  
  @Opt { help="how many times to parse" }
  Int n := 1
  
  @Opt { help="uses list handler (NullHandler is used otherwise)" }
  Bool list := false
  
  override Int run() {
    grammar := Grammar.fromStr(g.readAllStr)
    input := in.mmap
    m := Match()
    echo("Preparation finished")
    start := Duration.now
    n.times {
      input.seek(0)
      h := list ? ListHandler() : NullHandler()
      echo("Handler type: $h.typeof")
      p := Parser(grammar, h).run(input)
      m = p.match
    }
    d := Duration.now - start
    echo("Match: $m")    
    echo("Duration: $d.toLocale (${d.toMillis}ms)")
    return 0
  }
}