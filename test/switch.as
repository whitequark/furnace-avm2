package test {
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
