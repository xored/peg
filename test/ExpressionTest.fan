
class ExpressionTest : Test
{
  
  Void testE() {
    verifyEq(E.empty, Empty.val)
    verifyEq(E.any, Any.val)
    verifyEq(E.t("a"), T("a"))
    verifyEq(E.nt("a"), Nt("a"))
    
    verifyEq(E.seq([E.empty, E.empty]), Seq([E.empty, E.empty]))
    //verifyEq(Seq([E.empty, E.empty]), Seq([E.empty, E.empty]))
  }
  
}
