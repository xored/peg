
class ExpressionTest : Test
{
  
  Void testE() {
    // straightforward 
    verifyEq(E.empty, Empty())
    verifyEq(E.any, Any())
    verifyEq(E.t("a"), T("a"))
    verifyEq(E.nt("a"), Nt("a"))    
    verifyEq(E.seq([E.empty, E.any]), Seq([E.empty, E.any]))
    verifyEq(E.choice([E.empty, E.any]), Choice([E.empty, E.any]))
    verifyEq(E.rep(E.t("0")), Rep(E.t("0")))
    verifyEq(E.not(E.t("0")), Not(E.t("0")))
    
    // desugaring
    verifyEq(E.clazz(['0'..'1']), Class(['0'..'1']))
    verifyEq(E.opt(E.t("0")), Choice([E.t("0"), E.empty]))
    verifyEq(E.rep1(E.t("0")), Seq([E.t("0"), Rep(E.t("0"))]))
    verifyEq(E.and(E.t("0")), Not(Not(E.t("0"))))
    
    // special treatment of strings, ranges and lists
    verifyEq(E.seq(["t", "#nt", E.t("#nt"), "#"]), Seq([T("t"), Nt("nt"), T("#nt"), T("#")]))
    verifyEq(E.choice(["t", "#nt", E.t("#nt"), "#"]), Choice([T("t"), Nt("nt"), T("#nt"), T("#")]))
    
    verifyEq(E.seq([["t", "#nt"], "t"]), Seq([Seq([T("t"), Nt("nt")]), T("t")]))
    verifyEq(E.choice([["t", "#nt"], "t"]), Choice([Seq([T("t"), Nt("nt")]), T("t")]))
    
    verifyEq(E.rep('a'..'b'), Rep(Class(['a'..'b'])))
  }
  
}
