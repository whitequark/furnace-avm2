package test {
  class Literal {
    function test() {
      call(1, 1, 200, 200);
    }
  }

  class Arithmetics {
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

  class Logic {
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

  class Ternary {
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

  class Conditionals {
    function b(a:Boolean) {
      if(a)
        return foo();
      else
        return 1;
    }

    function a(a:Boolean) {
      baz();
      if(a) {
        foge();
      } else {
        huga();
      }
      piyo();
    }
  }

  class Loops {
    function e(f:Boolean) {
      do { f = tttest();
      } while(f);
    }

    function d() {
      while(true) {
        pow();
        if(frak()) { a(); break; b(); }
        weee();
      }
    }

    function b() {
      weee();
      for(var q:int = 1; q > 0; q++) {
        frak();
      }
    }
  }

  class Switch {
    function b(q:int):Boolean {
      for(;;) {
      switch(prop) {
      case 0x10:
      case 0x20:
        fuga();
      break;

      case 0x30:
        piyo();
      break;

      default:
        baz();
      break;
      }
      }
      return false;
    }

    function a(q:int):Boolean {
      switch(q) {
      case 0x10:
        hoge();
      case 0x20:
        fuga();
      break;
      case 0x30:
        piyo();
      break;
      default:
        baz();
      break;
      }
      return false;
    }
  }

  class Exceptions {
    function c() {
      try {
        hoge();
      } finally {
        piyo();
      }
    }
    function b() {
      try {
        hoge();
        throw 1;
        fuga();
      } catch(e: SecurityError) {
        piyo(e);
      }
    }
    function a() {
      try {
        hoge();
        throw 1;
        fuga();
      } catch(e: SecurityError) {
        piyo(e);
      } catch(e: Error) {
        throw e;
      }
    }
  }
}