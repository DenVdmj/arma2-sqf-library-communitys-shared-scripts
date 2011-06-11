// SQF
//
// sqf-library "\css\lib\arrays.sqf"
// Copyright (c) 2009-2010 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"

func(List2Set) = {
    private ["_col", "_rem"];
    _col = [];
    for "" from 1 to count _this do {
        if (count _this == 0) exitwith {};
        _rem = _this - [_this select 0];
        _col set [count _col, [_this select 0, count _this - count _rem]];
        _this = _rem;
    };
    _col
};

func(CanonizeSet) = {
    private ["_set", "_keys", "_pos"];
    _set = [];
    _keys = [];
    {
        #define __oldKey    (_x select 0)
        #define __oldValue  (_x select 1)
        #define __newPair   (_set select _pos)
        #define __newKey    (__newPair select 0)
        #define __newValue  (__newPair select 1)
        _pos = _keys find __oldKey;
        if (_pos == -1) then {
            push(_set, _x);
            push(_keys, __oldKey);
        } else {
            __newPair set [1, __newValue + __oldValue]
        };
        #undef __oldKey
        #undef __oldValue
        #undef __newPair
        #undef __newKey
        #undef __newValue
    } foreach _this;
    _set
};

func(GetUnduplicatedArray) = {
    private["_e","_i"];
    _i = 0;
    while { count _this != _i } do {
        _e = _this select _i;
        _this = [_e] + ( _this - [_e] );
        _i = _i + 1;
    };
    _this
};

func(MapGrep) = {
    private ["_SC0PE_", "_x"];
    _SC0PE_ = ["_SC0PE_", "_C0NF_", "_Fi1T3R_", "_1iST_", "_1_"];
    private _SC0PE_;
    _C0NF_ = arg(0);
    _Fi1T3R_ = arg(1);
    _1iST_ = [];
    for "_1_" from 0 to count _C0NF_ -1 do {
        _x = _C0NF_ select _1_;
        // safe own namespace and call user-callback-function
        _Fi1T3R_ call { private _SC0PE_; _x call _this } call {
            push(_1iST_, _this); // push if isn't nil
        };
    };
    _1iST_;
};

func(SortArray)={private["_s","_1","_2","_t","_i","_l","_u","_c","_a","_d"];_s={_a=_1 select
_l;_d=_2 select _l;while{_c=_l+_l+1;if(_c<=_u)then{if(_c<_u)then{if(_1 select _c+1>_1 select
_c)then{_c=_c+1}};if(_1 select _c>_a)then{_1 set[_l,_1 select _c];_2 set[_l,_2 select
_c];_l=_c;true}}}do{};_1 set[_l,_a];_2 set[_l,_d]};_1=_this select 0;_2=_this select
1;_t=count _1-1;_i=floor(_t*.5);while{_i>=0}do{_l=_i;_u=_t;call
_s;_i=_i-1};_i=_t;while{_i>0}do{_a=_1 select 0;_1 set[0,_1 select
_i];_1 set[_i,_a];_d=_2 select 0;_2 set[0,_2 select
_i];_2 set[_i,_d];_l=0;_u=_i-1;call _s;_i=_i-1};_this};


