package test {
  function hardcore(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    if(((a && b) ? (c || d) && e : b) && (a || b)) {
      return pow();
    } else {
      weeee();
    }
    duh();
  }
  function q(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    return ((a ? b : c) ? (b ? c : d) : (c ? d : e));
  }
  function a_I_b_E_c_I_d_E_e(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    return a ? b : (c ? d : e);
  }
  function a_I_b_I_c_E_d_E_e(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    return a ? (b ? c : d) : e;
  }
  function a_I_b_E_c(a: Boolean, b:Boolean, c:Boolean, d:Boolean, e:Boolean) : Boolean {
    return (1 > 2) ? b : c;
  }
}
