package test {
  class A {
    function A(test) {
    }
  }

  class Literal {
    public static var a:A = new A();
    public static const b:A = new A(1);
    public static var c:int;
    public var d:int;

    function test() {
      call(1, 1, 200, 200, -1, -50, 32767, 32768, -32760, -500000);
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
    function elsif(param1:Boolean, param2:Boolean) : Boolean {
      if(param1) {
        return true;
      } else if(param2) {
        return false;
      } else {
        return null;
      }
    }

    function els(param1:Object, param2:String, param3:String) : Boolean {
      var _loc_4:Object = null;
      if (param1 != null)
      {
          _loc_4 = param1[param2];
          if (_loc_4 != null)
          {
              if (_loc_4[param3] != null)
              {
                  return true;
              }
              a();
          }
          b();
      }
      heys();
      return false;
    }

    function els2(param1:Object, param2:String, param3:String) : Boolean {
      var _loc_4:Object = null;
      if (param1 != null)
      {
          _loc_4 = param1[param2];
          if (_loc_4 != null)
          {
              if (_loc_4[param3] != null)
              {
                  return true;
              }
          }
      }
      heys();
      return false;
    }

    function b(a:Boolean) {
      if(a)
        return foo();
      else
        return 1;
    }

    function q(a:Boolean, b:Boolean) {
      if(b) {
        if(a) {
          foo();
        }
      }
      baz();
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

    function nested(a:Boolean, b:Boolean) {
      if(a) {
        foo();
      } else {
        if(b) {
          bar();
        } else {
          baz();
        }
      }
    }
  }

  class Loops {
    function f(f:Boolean) {
      do {
        f = tttest();
        if(rand() > 0)
          break;
        bar();
        if(rand() < 0)
          continue;
        foo();
        if(k)
          return;
        end();
      } while(f);
    }

    function e(f:Boolean) {
      do {
        f = tttest();
        if(rand() > 0)
          break;
        bar();
        if(rand() < 0)
          continue;
        foo();
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

    function a() {
      var i:int = 0;
      while(i++ < 5) {
        hello();
      }
      return i;
    }
  }

  class Switch {
    function improper_switch(q:int):Boolean {
      switch(q) {
      case 0x10:
        hoge();
        break;
      case "test":
        fuga();
        break;
      case 0x30:
        piyo();
        break;
      case 0x40:
        fuck();
        break;
      }
      return false;
    }

    function proper_switch(q:int):Boolean {
      switch(q) {
      case 1:
        hoge();
      break;
      case 2:
        fuga();
      break;
      case 3:
        piyo();
      break;
      case 4:
        bar();
      break;
      default:
        baz();
      break;
      }
      return false;
    }

    function fallthrough_switch(q:int):Boolean {
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

  class Closures {
    function a() {
      var a:int = 1;
      var f = function(param) {
        var b:int = 10;
        return a + this.fuga() + hoge() + param;
      };
      var q = function() {
        test123();
      };
      q();
      return f;
    }
  }

  class Exceptions {
    function f() {
      if(a) {
        try {
          try {
            a();
          } catch(e) {
            b();
          }
          hoge();
        } catch(q: SecurityError) {
          piyo();
        }
      }
    }
    function e() {
      if(a) {
        try {
          try {
            a();
          } catch(e) {
            b();
          }
          hoge();
        } finally {
          piyo();
        }
      }
    }
    function d() {
      if(a) {
        try {
          hoge();
        } finally {
          piyo();
        }
      }
    }
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