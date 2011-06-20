
@Js
internal enum class ExpressionProvider : LazyRuleProvider {
  INSTANCE;
  
  override Rule rule() {
    PegGrammar.Expression    
  }
}

@Js
const class PegGrammar
{ 
  static const PegGrammar instance := PegGrammar()
  
  private new make(){}
  
  ******************************************************************************
  ** Lexical syntax
  ****************************************************************************** 
  
  ** EndOfFile <- !.
  static const Rule EndOfFile := TestNotRule(SkipRule(), Str <|EndOfFile <- !.|>)
  
  ** EndOfLine <- ’\r\n’ / ’\n’ / ’\r’
  static const Rule EndOfLine :=
    FirstOfRule([
      LiteralRule("\r\n"),
      LiteralRule("\r"),
      LiteralRule("\n")
    ], Str <|EndOfLine <- ’\r\n’ / ’\n’ / ’\r’|>)
  
  ** Space <- ’ ’ / ’\t’ / EndOfLine
  static const Rule Space := 
    FirstOfRule([
      LiteralRule(" "), 
      LiteralRule("\t"), 
      EndOfLine
    ], Str <|Space <- ’ ’ / ’\t’ / EndOfLine|>)
  
  ** Comment <- ’#’ (!EndOfLine .)* EndOfLine
  internal static const Rule EndOfComment := FirstOfRule([EndOfFile, EndOfLine])
  static const Rule Comment := 
    SeqRule([
      LiteralRule("#"), 
      ZeroOrMoreRule(SeqRule([TestNotRule(EndOfComment), SkipRule()])), 
      EndOfComment
    ], Str <|Comment <- ’#’ (!EndOfLine .)* EndOfLine|>)
  
  ** Spacing <- (Space / Comment)*
  static const Rule Spacing := ZeroOrMoreRule(FirstOfRule([Space, Comment]), 
    Str <|** Spacing <- (Space / Comment)*|>)
  
  ** DOT <- ’.’ Spacing
  static const Rule DOT := SeqRule([LiteralRule("."), Spacing], Str <|DOT <- ’.’ Spacing|>)
  
  ** CLOSE <- ’)’ Spacing
  static const Rule CLOSE := SeqRule([LiteralRule(")"), Spacing], Str <|CLOSE <- ’)’ Spacing|>)
  
  ** OPEN <- ’(’ Spacing
  static const Rule OPEN := SeqRule([LiteralRule("("), Spacing], Str <|OPEN <- ’(’ Spacing|>)
    
  ** PLUS <- ’+’ Spacing
  static const Rule PLUS := SeqRule([LiteralRule("+"), Spacing], Str <|PLUS <- ’+’ Spacing|>)
    
  ** STAR <- ’*’ Spacing
  static const Rule STAR := SeqRule([LiteralRule("*"), Spacing], Str <|STAR <- ’*’ Spacing|>)
    
  ** QUESTION <- ’?’ Spacing
  static const Rule QUESTION := SeqRule([LiteralRule("?"), Spacing], Str <|QUESTION <- ’?’ Spacing|>)
    
  ** NOT <- ’!’ Spacing
  static const Rule NOT := SeqRule([LiteralRule("!"), Spacing], Str <|NOT <- ’!’ Spacing|>)
    
  ** AND <- ’&’ Spacing
  static const Rule AND := SeqRule([LiteralRule("&"), Spacing], Str <|AND <- ’&’ Spacing|>)
    
  ** SLASH <- ’/’ Spacing
  static const Rule SLASH := SeqRule([LiteralRule("/"), Spacing], Str <|SLASH <- ’/’ Spacing|>)
    
  **  LEFTARROW <- ’<-’ Spacing
  static const Rule LEFTARROW := SeqRule([LiteralRule("<-"), Spacing], Str <|LEFTARROW <- ’<-’ Spacing|>)
    
  **  COLON <- ’:’ Spacing
  static const Rule COLON := SeqRule([LiteralRule(":"), Spacing], Str <|COLON <- ’:’ Spacing|>)
    
  **  AT <- ’@’ Spacing
  static const Rule AT := SeqRule([LiteralRule("@"), Spacing], Str <|AT <- ’@’ Spacing|>)
    
  ** Char <- ’\\’ [nrt’"\[\]\\]
  ** / ’\\’ [0-2][0-7][0-7]
  ** / ’\\’ [0-7][0-7]?
  ** / !‘\\‘ .
  internal static const Rule EscapeChar :=
    SeqRule([
      LiteralRule("\\"),
      ClassRule([
        CharRule('n'), CharRule('r'), CharRule('t'), CharRule('\''),
        CharRule('"'), CharRule('['), CharRule(']'), CharRule('\\')
      ])
    ], Str <|’\\’ [nrt’"\[\]\\]|>)  
  internal static const Rule Unicode := SeqRule([LiteralRule("\\u"), 
    RepeatRule(ClassRule([RangeRule('0'..'9'), RangeRule('a'..'f'), RangeRule('A'..'F')]), 4, 4)])
  internal static const Rule SimpleChar := SeqRule([TestNotRule(LiteralRule("\\")), SkipRule()])
  static const Rule Char := FirstOfRule([EscapeChar, Unicode, SimpleChar], 
    Str <|Char <-   ’\\’ [nrt’"\[\]\\]
                  / ’\\’ [0-2][0-7][0-7]
                  / ’\\’ [0-7][0-7]?
                  / !‘\\‘ .|>)
    
  ** Range <- Char ’-’ Char / Char
  static const Rule Range := FirstOfRule([SeqRule([Char, LiteralRule("-"), Char]), Char],
    Str <|Range <- Char ’-’ Char / Char|>)
    
  ** Class <- ’[’ (!’]’ Range)* ’]’ Spacing
  static const Rule Class := 
    SeqRule([
      LiteralRule("["),
      ZeroOrMoreRule(SeqRule([TestNotRule(LiteralRule("]")), PegGrammar.Range])),
      LiteralRule("]"),
      Spacing
    ], Str <|Class <- ’[’ (!’]’ Range)* ’]’ Spacing|>)
    
  ** Literal <-   [’] (![’] Char)* [’] Spacing
  **            / ["] (!["] Char)* ["] Spacing
  internal static const Rule Quoted := 
      SeqRule([
        LiteralRule("'"),
        ZeroOrMoreRule(SeqRule([TestNotRule(LiteralRule("'")), Char])),
        LiteralRule("'"),
        Spacing
      ], Str <|[’] (![’] Char)* [’] Spacing|>)
  internal static const Rule DoubleQuoted := 
      SeqRule([
        LiteralRule("\""),
        ZeroOrMoreRule(SeqRule([TestNotRule(LiteralRule("\"")), Char])),
        LiteralRule("\""),
        Spacing
      ], Str <|["] (!["] Char)* ["] Spacing|>)
  static const Rule Literal := FirstOfRule([Quoted, DoubleQuoted], 
    Str <|Literal <-   [’] (![’] Char)* [’] Spacing
                     / ["] (!["] Char)* ["] Spacing)|>)
  
  ** IdentStart <- [a-zA-Z_]
  protected static const Rule IdentStart := 
    ClassRule([RangeRule('a'..'z'), RangeRule('A'..'Z'), CharRule('_')], Str <|IdentStart <- [a-zA-Z_]|>)
  
  ** IdentCont <- IdentStart / [0-9]
  protected static const Rule IdentCont := FirstOfRule([IdentStart, RangeRule('0'..'9')], 
    Str <|IdentCont <- IdentStart / [0-9]|>)
      
  static const Rule Ident := 
    SeqRule([IdentStart, ZeroOrMoreRule(IdentCont)], 
      Str <|Ident <- IdentStart IdentCont*|>)
      
  static const Rule Identifier := 
    SeqRule([SeqRule([
      ZeroOrOneRule(SeqRule([Ident, COLON])), 
      Ident]), 
      Spacing], 
      Str <|Identifier <- (Ident COLON)? Ident Spacing|>)
      
  ******************************************************************************
  ** Hierarchical syntax
  ******************************************************************************
    
  ** Primary <- Identifier !LEFTARROW
  ** / OPEN Expression CLOSE
  ** / Literal / Class / DOT
  internal static const Rule IdExpr := SeqRule([Identifier, TestNotRule(LEFTARROW)])
      
  internal static const Rule ParenExpr := 
    SeqRule([OPEN, LazyRule(ExpressionProvider.INSTANCE, "Expression"), CLOSE])
      
  static const Rule Primary := FirstOfRule([IdExpr, ParenExpr, Literal, Class, DOT], 
    Str <|Primary <-   Identifier !LEFTARROW 
                     / OPEN Expression CLOSE
                     / Literal / Class / DOT|>)
  
  ** Suffix <- Primary (QUESTION / STAR / PLUS)?
  static const Rule Suffix := SeqRule([Primary, ZeroOrOneRule(FirstOfRule([QUESTION, STAR, PLUS]))], 
    Str <|Suffix <- Primary (QUESTION / STAR / PLUS)?|>)
    
  ** Prefix <- (AND / NOT)? Suffix
  static const Rule Prefix := SeqRule([ZeroOrOneRule(FirstOfRule([AND, NOT])), Suffix], 
    Str <|Prefix <- (AND / NOT)? Suffix|>)
    
  ** Sequence <- Prefix*
  static const Rule Sequence := ZeroOrMoreRule(Prefix, Str <|Sequence <- Prefix*|>)
    
  ** Expression <- Sequence (SLASH Sequence)*
  static const Rule Expression := SeqRule([Sequence, ZeroOrMoreRule(SeqRule([SLASH, Sequence]))], 
    Str <|Expression <- Sequence (SLASH Sequence)*|>)
    
  ** Definition <- Identifier LEFTARROW Expression
  static const Rule Definition := SeqRule([Identifier, LEFTARROW, Expression], 
    Str <|Definition <- Identifier LEFTARROW Expression|>)
      
  static const Rule Namespace := 
    SeqRule([AT, Ident, Spacing], 
      Str <|Namespace <- AT Ident Spacing|>)  
   
  ** Grammar <- Spacing Definition+ EndOfFile
  static const Rule Grammar := SeqRule([Spacing, ZeroOrOneRule(Namespace), OneOrMoreRule(Definition), EndOfFile], 
    Str <|Grammar <- Spacing Namespace? Definition+ EndOfFile|>)
}
