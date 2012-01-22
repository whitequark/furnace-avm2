package test {
  function b() {
    var a:int = 0;
    var b:int;
    b = (a += 1);
    return (b -= (a += 1));
  }
  function a() {
    var a:int = 0;
    var b:int = ++a;
    var c:int = a++;
    return a;
  }
}
