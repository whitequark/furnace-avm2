{ func1
//d0
_as3_getlocal <0>
//30
_as3_pushscope
//2c d8 2e
_as3_pushstring "TechItem: slot "
//10 09 00 00
_as3_jump offset: 9
//1c
_as3_pushwith
//af
_as3_greaterthan
//57
_as3_newactivation
//a0
_as3_add
//b0
_as3_greaterequals
//a5
_as3_lshift
//b3
_as3_istypelate
//1f
_as3_hasnext
//21
_as3_pushundefined
//d0
_as3_getlocal <0>
//10 09 00 00
_as3_jump offset: 9
//c6
_as3_subtract_i
//d0
_as3_getlocal <0>
//74
_as3_convert_u
//d6
_as3_setlocal <2>
//21
_as3_pushundefined
//96
_as3_not
//a7
_as3_urshift
//c0
_as3_increment_i
//57
_as3_newactivation
//66 fa 30
_as3_getproperty slot
//a0
_as3_add
//2c a6 20
_as3_pushstring " type: "
//a0
_as3_add
//d0
_as3_getlocal <0>
//66 b5 2f
_as3_getproperty *::name
//a0
_as3_add
//2c 98 21
_as3_pushstring ", status "
//a0
_as3_add
//5d a4 37
_as3_findpropstrict getNameByStatus
//d0
_as3_getlocal <0>
//66 ce 03
_as3_getproperty status
//46 a4 37 01
_as3_callproperty getNameByStatus(param count:1)
//a0
_as3_add
//2c 93 21
_as3_pushstring ", amount: "
//a0
_as3_add
//d0
_as3_getlocal <0>
//66 96 02
_as3_getproperty amount
//a0
_as3_add
//2c 96 21
_as3_pushstring ", secsLeft: "
//a0
_as3_add
//d0
_as3_getlocal <0>
//66 ee 06
_as3_getproperty secondsLeft
//a0
_as3_add
//48
_as3_returnvalue
}
{ func2
//d0
_as3_getlocal <0>
//30
_as3_pushscope
//2c d8 2e
_as3_pushstring "TechItem: slot "
//10 01 00 00
_as3_jump offset: 1
//1c
_as3_pushwith
//af
_as3_greaterthan
//57
_as3_newactivation
}