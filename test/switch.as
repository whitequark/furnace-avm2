function propel_switch(q:int):Boolean {
  switch(q) {
  case 1:
    print("hoge");
  break;
  case 2:
    print("fuga");
  break;
  case 3:
    print("piyo");
  break;
  case 5:
    print("bar");
  break;
  default:
    print("baz");
  break;
  }
  return false;
}

propel_switch(0); // baz
propel_switch(1); // hoge
propel_switch(2); // fuga
propel_switch(3); // piyo
propel_switch(4); // baz
propel_switch(5); // bar