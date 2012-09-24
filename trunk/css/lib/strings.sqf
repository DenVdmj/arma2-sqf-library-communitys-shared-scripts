// SQF
//
// sqf-library "\css\lib\strings.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

//
// Function func(JoinString)
//
// Syntax:
//     [array listOfStrings] invoke(JoinString)
//     [array listOfStrings, string glue] invoke(JoinString)
//
// Fast string concatenation.
// Example:
//     [magazines player, ", "] invoke(JoinString)
//

func(JoinString) = {

    private ["_list", "_char", "_size", "_subsize", "_oversize", "_j"];

    _list = arg(0);
    _char = argOr(1, "");

    if (count _list < 1) exitwith {""};

    for "" from 1 to ceil __log2(count _list) do {
        _size = count _list / 2;
        _subsize = floor _size;
        _oversize = ceil _size;
        _j = 0;
        for "_i" from 0 to _subsize - 1 do {
            _list set [_i, (_list select _j) + _char + (_list select (_j+1))];
            _j = _j + 2;
        };
        if (_subsize != _oversize) then { // to add a tail
            _list set [_j/2, _list select _j];
        };
        _list resize _oversize;
    };

    _list select 0;
};


//
// Function func(PathInfoGetDirName)
//
// Syntax:
//     (string fullpath) invoke(PathInfoGetDirName)
//

func(PathInfoGetDirName) = {
    private ["_arr", "_pos"];
    _arr = toArray _this;
    _pos = (for "_i" from count _arr - 1 to 0 step -1 do {
        if ((_arr select _i) == 92) exitwith { _i };
        -1;
    });
    if (_pos == -1) exitwith { "" };
    _arr resize _pos;
    toString _arr;
};

//
// Function func(PathInfoGetFileName)
//
// Syntax:
//     (string fullpath) invoke(PathInfoGetFileName)
//

func(PathInfoGetFileName) = {
    private ["_arr", "_pos", "_name"];
    _arr = toArray _this;
    _pos = 1 + (for "_i" from count _arr - 1 to 0 step -1 do {
        if ((_arr select _i) == 92) exitwith { _i };
        -1;
    });
    if (_pos == -1) exitwith { _this };
    _name = [];
    for "_i" from _pos to count _arr - 1 do {
        _name set [count _name, _arr select _i];
    };
    toString _name;
};
