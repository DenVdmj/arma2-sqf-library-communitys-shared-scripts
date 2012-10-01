// SQF
//
// sqf-library "\css\lib\arrays.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

//
// Function func(List2Set)
// Syntax:
//     (array listOfAnyComparableValues) invoke(List2Set)
// Converts an array-list to array-set. Format of array-set:
//     [
//         ["item 1", count of these items],
//         ["item 2", count of these items],
//         ...
//         ["item N", count of these items]
//     ]
// Example:
//     magazines player invoke(List2Set)
// Result:
//     [
//         ["30Rnd_556x45_Stanag", 6],
//         ["HandGrenade_West", 4]
//     ]
//

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

//
// Function func(CanonizeSet)
// Syntax:
//     (array listOfAnyComparableValues) invoke(CanonizeSet)
// Function fixes invalid array-set, an example of usage:
//     (
//         (magazines officer1 invoke(List2Set)) +
//         (magazines officer2 invoke(List2Set))
//     ) invoke(CanonizeSet)
// Result:
//     [
//         ["30Rnd_556x45_Stanag", 6],
//         ["7Rnd_45ACP_1911", 8]
//     ]
//

func(CanonizeSet) = {
    private ["_set", "_keys", "_pos", "_pairref"];
    _set = [];
    _keys = [];
    #define __key(r)   ((r) select 0)
    #define __value(r) ((r) select 1)
    {
        _pos = _keys find __key(_x);
        if (_pos == -1) then {
            __push(_set,_x);
            __push(_keys,__key(_x));
        } else {
            _pairref = _set select _pos;
            _pairref set [1, __value(_pairref) + __value(_x)]
        };
    } foreach _this;
    #undef __key
    #undef __value
    _set
};

//
// Function func(GetUnduplicatedArray)
// Syntax:
//     _arrayWithDuplicates invoke(UnduplicatedArray)
// Deletes all duplicate entries in array. Returns new array.
//

func(GetUnduplicatedArray) = {
    private ["_e", "_i"];
    _i = 0;
    while { count _this != _i } do {
        _e = _this select _i;
        _this = [_e] + ( _this - [_e] );
        _i = _i + 1;
    };
    _this
};

//
// Function func(RemoveItemsFromArray)
// Syntax:
//     [array list, arrayOfAnyValues removedEntries] invoke(RemoveItemsFromArray)
// Deletes all specified entries from specified array. Returns the same modified array.
// Use for cases where it is important to keep a reference to an array.
//

func(RemoveItemsFromArray) = {
    private ["_array", "_items", "_offset", "_item"];
    _array = arg(0);
    _items = arg(1);
    _offset = 0;
    for "_i" from 0 to count _array do {
        _item = _array select _i;
        if (_offset > 0) then {
            _array set [_i - _offset, _item]
        };
        if (_item in _items) then {
            _offset = _offset + 1;
        };
    };
    _array;
};

//
// Function func(MapGrep)
// Syntax:
//     [array list, code filter] invoke(MapGrep)
//     [config class, code condition] invoke(MapGrep)
// Returns an array for those elements for which the condition evaluates to notNil.
// Examples:
//
//     // Returns all classnames of cars.
//     [configFile >> "CfgVehicles", {
//         if (isClass _x) then {
//            if (
//                getNumber(_x >> "scope") > 0 &&
//                getText(_x >> "simulation") == "car"
//            ) then {
//                configName _x
//            }
//         }
//     }] invoke(MapGrep)
//
//     // names of players' soldiers
//     [units player, { name _x }] invoke(MapGrep)
//
//     // positions of all cars requiring repairs:
//     [allUnits, {
//         if (_x isKindOf "Car" && ! canMove _x) then { getPosASL2 _x }
//     }] invoke(MapGrep)
//

func(MapGrep) = {
    private "_x";
    _this set [2, []];
    for "____i" from 0 to count arg(0) -1 do {
        _x = arg(0) select ____i;
        _this set [3, _x call arg(1)];
        if !(isNil {arg(3)}) then {
            __push(arg(2), arg(3));
        };
    };
    arg(2);
};

//
// Function func(SortArray)
// Syntax:
//     (two parralel arrays) invoke(SortArray)
// Sort two parralel arrays (using a heapsort algorithm, O(n log n)).
// Format of arrays:
//     [
//         [values],
//         [linked data]
//     ]
// Example:
//     [
//         [  32,   43,   12,   3,   6565,   43,   3,   4,   5,   234 ],
//         ["_32","_43","_12","_3","_6565","_43","_3","_4","_5","_234 ]
//     ] invoke(SortArray)
// Result:
//     [
//         [  3,   3,   4,   5,   12,   32,   43,   43,   234,   6565 ],
//         ["_3","_3","_4","_5","_12","_32","_43","_43","_234","_6565"]
//     ]
//

func(SortArray)={private["_s","_1","_2","_t","_i","_l","_u","_c","_a","_d"];_s={_a=_1 select
_l;_d=_2 select _l;while{_c=_l+_l+1;if(_c<=_u)then{if(_c<_u)then{if(_1 select _c+1>_1 select
_c)then{_c=_c+1}};if(_1 select _c>_a)then{_1 set[_l,_1 select _c];_2 set[_l,_2 select
_c];_l=_c;true}}}do{};_1 set[_l,_a];_2 set[_l,_d]};_1=_this select 0;_2=_this select
1;_t=count _1-1;_i=floor(_t*.5);while{_i>=0}do{_l=_i;_u=_t;call
_s;_i=_i-1};_i=_t;while{_i>0}do{_a=_1 select 0;_1 set[0,_1 select
_i];_1 set[_i,_a];_d=_2 select 0;_2 set[0,_2 select
_i];_2 set[_i,_d];_l=0;_u=_i-1;call _s;_i=_i-1};_this};
