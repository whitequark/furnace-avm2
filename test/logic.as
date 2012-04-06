package test {
  function P_a_or_b_p_and_P_c_and_d_p_or_e(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    var v:Boolean = (a || b) && (c && d) || e;
    away();
    return v;
  }
  function a_or_b(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    if(a || b) {
      yes();
    } else {
      no();
    }
  }
  function a_and_b_and_c(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    return a && (b && c);
  }
  function P_a_and_b_p_and_c(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    return (a && b) && c;
  }
  function a_and_b(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    return a && b;
  }
}
