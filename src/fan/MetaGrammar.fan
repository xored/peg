
** PEG meta-grammar.
** This grammar is described in the original PEG paper 
** (http://pdos.csail.mit.edu/~baford/packrat/popl04/).
** However, the grammar is modified to support some features like grammar name spaces and lazy repetition operator.
** 
** This grammar is considered a low-level API and made public for special purposes only. 
** Please, avoid using it, if possible. It may change in future without backward compatibility.  
@Js
const class MetaGrammar : GrammarImpl
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
      
      "CURLYOPEN" : E.t("{"),
      
      "CURLYCLOSE" : E.t("}"),
      
      "PLUS" : E.t("+"),
      
      "STAR" : E.t("*"),
      
      "QUESTION" : E.t("?"),
      
      "NOT" : E.t("!"),
      
      "AND" : E.t("&"),
      
      "SLASH" : E.t("/"),
      
      "LEFTARROW" : E.t("<-"),
      
      "COLON" : E.t(":"),
      
      "AT" : E.t("@"),
      
      "HexDigit" : E.clazz(['a'..'f', 'A'..'F', '0'..'9']),
      
      "Char" : E.choice([
        ["\\", E.clazz(['n', 'r', 't', '\'', '"', '[', ']', '\\'])],
        ["\\u", "#HexDigit", "#HexDigit", "#HexDigit", "#HexDigit", E.opt("#HexDigit")],
        [E.not("\\"), E.any]
      ]),
      
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
      
      "Ident" : E.seq(["#IdentStart", E.rep("#IdentCont")]),
      
      "Namespace" : E.nt("Ident"),
      
      // Identifier which can have explicit namespace
      "Identifier" : E.seq([E.opt(["#Ident", "#COLON"]), "#Ident"]),
      
      // Identifier which can NOT have explicit namespace
      "DefinitionIdentifier" : E.nt("Ident"),
      
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
      
      "SparseCall" : E.seq(["#CURLYOPEN", "#Spacing", "#Identifier", "#Spacing", "#CURLYCLOSE", "#Spacing", E.and("#Expression")]), 
      
      "LazyRepetition" : E.seq(["#STAR", "#QUESTION", "#Spacing", "#Prefix"]),
      
      "Suffix" : E.seq(["#Primary", E.opt([E.choice(["#LazyRepetition","#QUESTION", "#STAR", "#PLUS"]), "#Spacing"])]),
      
      "Prefix" : E.seq([E.opt([E.choice(["#AND", "#NOT"]), "#Spacing"]), "#Suffix"]),
      
      "Sequence" : E.rep(E.seq([E.opt("#SparseCall"), "#Prefix"])),
      
      "Expression" : E.choice(["#SparseBlock", E.seq(["#Sequence", E.rep(["#SLASH", "#Spacing", "#Sequence"])])]),
      
      "SparseBlock" : E.seq(["#CURLYOPEN", "#Spacing", E.rep1([E.not("#SparseBlock"), "#Definition"]), "#CURLYCLOSE", "#Spacing"]),
      
      "Definition" : E.seq(["#DefinitionIdentifier", "#Spacing", "#LEFTARROW", "#Spacing", E.choice(["#SparseBlock", "#Expression"])]),
      
      "Grammar" : E.seq([
        "#Spacing", 
        E.opt(["#AT", "#Spacing", "#Namespace", "#Spacing"]),
        E.rep1("#Definition"), 
        "#EndOfFile"
      ])
    ]
  }
}
