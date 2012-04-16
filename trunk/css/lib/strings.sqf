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