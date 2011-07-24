
** PEG meta-grammar.
** This grammar is described in the original PEG paper 
** (http://pdos.csail.mit.edu/~baford/packrat/popl04/).
** Non-terminals symbols are the same as in the paper.

// Actually, meta grammar should be a singleton. 
// But Fantom has troubles with static variables initialization order 
// (at least in JS, http://fantom.org/sidewalk/topic/1381). And some expressions are singletons.
// So, to avoid hard bugs, let the meta grammar be a normal class.
// Performance overhead is not important.
@Js
internal const class MetaGrammar : GrammarImpl
{
  new make() : super(createMetaRules, "Grammar") {}

  ** Create a map of meta grammar rules.
  private static Str:Expression createMetaRules() {
    Str:Expression [
      
      // Lexical syntax =========================================================
      
      "EndOfFile" : E.not(E.any),
      
      "EndOfLine" : E.choice(["\r\n", "\n", "\r"]),
      
      "Space" : E.choice([" ", "\t", "#EndOfLine"]),
      
      "Comment" : E.seq(["#", E.rep([E.not("#EndOfLine"), E.any]), "#EndOfLine"]),
      
      "Spacing" : E.rep(E.choice(["#Space", "#Comment"])),
      
      "DOT" : E.seq([".", "#Spacing"]),
      
      "CLOSE" : E.seq([")", "#Spacing"]),
      
      "OPEN" : E.seq(["(", "#Spacing"]),
      
      "PLUS" : E.seq(["+", "#Spacing"]),
      
      "STAR" : E.seq(["*", "#Spacing"]),
      
      "QUESTION" : E.seq(["?", "#Spacing"]),
      
      "NOT" : E.seq(["!", "#Spacing"]),
      
      "AND" : E.seq(["&", "#Spacing"]),
      
      "SLASH" : E.seq(["/", "#Spacing"]),
      
      "LEFTARROW" : E.seq(["<-", "#Spacing"]),
      
      "Char" : E.choice([
        ["\\", E.choice(["n", "r", "t", "'", "\"", "[", "]", "\\"])],
        [E.not("\\"), E.any]
      ]), // TODO: implement character code support such as \213 here
      
      "Range" : E.choice([
        ["#Char", E.t("-"), "#Char"],
        "#Char"
      ]),
      
      "Class" : E.seq(["[", E.rep([E.not("]"), "#Range"]), "]", "#Spacing"]),
      
      "Literal" : E.choice([
        ["'", E.rep([E.not("'"), "#Char"]), "'", "#Spacing"],
        ["\"", E.rep([E.not("\""), "#Char"]), "\"", "#Spacing"]
      ]),
      
      "IdentStart" : E.choice(['a'..'z', 'A'..'Z', "_"]),
      
      "IdentCont" : E.choice(["#IdentStart", '0'..'9']),
      
      "Identifier" : E.seq(["#IdentStart", E.rep("#IdentCont"), "#Spacing"]),
      
      // Hierarchical syntax ====================================================
    
      "Primary" : E.choice([
        ["#Identifier", E.not("#LEFTARROW")],
        ["#OPEN", "#Expression", "#CLOSE"],
        "#Literal",
        "#Class",
        "#DOT"
      ]),
      
      "Suffix" : E.seq(["#Primary", E.opt(E.choice(["#QUESTION", "#STAR", "#PLUS"]))]),
      
      "Prefix" : E.seq([E.opt(E.choice(["#AND", "#NOT"])), "#Suffix"]),
      
      "Sequence" : E.rep("#Prefix"),
      
      "Expression" : E.seq(["#Sequence", E.rep(["#SLASH", "#Sequence"])]),
      
      "Definition" : E.seq(["#Identifier", "#LEFTARROW", "#Expression"]),
      
      "Grammar" : E.seq(["#Spacing", E.rep1("#Definition"), "#EndOfFile"])
    ]
  }
}
