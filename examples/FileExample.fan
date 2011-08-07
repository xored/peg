
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
  
  override Int run() {
    grammar := Grammar.fromStr(g.readAllStr)
    input := in.readAllStr.toBuf
    m := Match()
    echo("Preparation finished")
    start := Duration.now
    n.times {
      input.seek(0)
      p := Parser(grammar, ListHandler()).run(input)
      m = p.match
    }
    d := Duration.now - start
    echo("Match: $m")
    echo("Duration: $d.toLocale")
    return 0
  }
}