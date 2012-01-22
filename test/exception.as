package test {
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
