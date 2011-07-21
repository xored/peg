
internal class Ttt {
  Obj a
  new make(Obj a) { this.a = a }
  
  override Int hash() { a.hash }
  
  override Bool equals(Obj? other) {
    if (null == other) {
      return false
    }
    if (this.typeof != other.typeof) {
      echo("Typeof differs: this = $this.typeof, other = $other.typeof")
      return false
    }
    return a == (other as Ttt).a
  }
}

internal class TttKid : Ttt {
  new make(Obj a) : super([a]) {}
}

class PegExample
{
  static Void main(Str[] args) {
    Obj[] l1 := [TttKid("a"), TttKid("b")]
    Obj[] l2 := [TttKid("a"), TttKid("b")]
    echo("${l1 == l2}, $l1.hash == $l2.hash")
  }
}
