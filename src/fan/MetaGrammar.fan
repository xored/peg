
** PEG meta-grammar.
** This grammar is described in the original PEG paper 
** (http://pdos.csail.mit.edu/~baford/packrat/popl04/).
** Non-terminals symbols are the same as in the paper.
** However, the grammar is modified slightly to make parsing easier.
internal const class MetaGrammar : GrammarImpl
{
  static const MetaGrammar val := MetaGrammar()
  
  private new make() : super("Grammar", createMetaRules) {}

  ** Create a map of meta grammar rules.
  private static Str:Expression createMetaRules() {
    Str:Expression [
      
      // Lexical syntax =========================================================
      
      "EndOfFile" : E.not(E.any),
      
      "EndOfLine" : E.choice(["\r\n", "\n", "\r"]),
      
      "Space" : E.choice([" ", "\t", "#EndOfLine"]),
      
      "Comment" : E.seq(["#", E.rep([E.not("#EndOfLine"), E.any]), "#EndOfLine"]),
      
      "Spacing" : E.rep(E.choice(["#Space", "#Comment"])),
      
      "DOT" : E.t("."),
      
      "CLOSE" : E.t(")"),
      
      "OPEN" : E.t("("),
      
      "PLUS" : E.t("+"),
      
      "STAR" : E.t("*"),
      
      "QUESTION" : E.t("?"),
      
      "NOT" : E.t("!"),
      
      "AND" : E.t("&"),
      
      "SLASH" : E.t("/"),
      
      "LEFTARROW" : E.t("<-"),
      
      "Char" : E.choice([
        ["\\", E.clazz(['n', 'r', 't', '\'', '"', '[', ']', '\\'])],
        [E.not("\\"), E.any]
      ]), // TODO: implement character code support such as \213 here
      
      "Range" : E.choice([
        ["#Char", E.t("-"), "#Char"],
        "#Char"
      ]),
      
      "Class" : E.seq(["[", E.rep([E.not("]"), "#Range"]), "]"]),
      
      "Literal" : E.choice([
        ["'", E.rep([E.not("'"), "#Char"]), "'"],
        ["\"", E.rep([E.not("\""), "#Char"]), "\""]
      ]),
      
      "IdentStart" : E.clazz(['a'..'z', 'A'..'Z', '_']),
      
      "IdentCont" : E.choice(["#IdentStart", '0'..'9']),
      
      "Identifier" : E.seq(["#IdentStart", E.rep("#IdentCont")]),
      
      // Hierarchical syntax ====================================================
    
      "Primary" : E.seq([
        E.choice([
          ["#Identifier", "#Spacing", E.not("#LEFTARROW")],
          ["#OPEN", "#Spacing", "#Expression", "#CLOSE"],
          "#Literal",
          "#Class",
          "#DOT"
        ]),
        "#Spacing"
      ]),
      
      "Suffix" : E.seq(["#Primary", E.opt([E.choice(["#QUESTION", "#STAR", "#PLUS"]), "#Spacing"])]),
      
      "Prefix" : E.seq([E.opt([E.choice(["#AND", "#NOT"]), "#Spacing"]), "#Suffix"]),
      
      "Sequence" : E.rep("#Prefix"),
      
      "Expression" : E.seq(["#Sequence", E.rep(["#SLASH", "#Spacing", "#Sequence"])]),
      
      "Definition" : E.seq(["#Identifier", "#Spacing", "#LEFTARROW", "#Spacing", "#Expression"]),
      
      "Grammar" : E.seq(["#Spacing", E.rep1("#Definition"), "#EndOfFile"])
    ]
  }
}
