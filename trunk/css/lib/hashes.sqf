// SQF
//
// sqf-library "\css\lib\hashes.sqf"
// Copyright (c) 2009-2013 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

//
// Function func(HashCreate)
// Syntax:
//     _someHash = invoke(HashCreate);
//

func(HashCreate) = {
    ["logic" createVehicleLocal [0,0,0], []]
};

//
// Function func(HashDelete)
// Syntax:
//     _someHash invoke(HashDelete);
//

func(HashDelete) = {
    // free memory
    deleteVehicle arg(0);
    _this set [0, nil];
    _this set [1, nil];
    _this resize 0;
};

//
// Function func(HashSet)
// Syntax:
//     [_someHash, _newKey, _newValue] invoke(HashSet)
//

func(HashSet) = {
    private ["_hash", "_key", "_value"];
    _hash = arg(0);
    _key = arg(1);
    _value = arg(2);
    if (isNil func(HashGet)) then {
        __push(_hash select 1, _key);
    };
    (_hash select 0) setVariable [_key, _value];
};

//
// Function func(HashGet)
// Syntax:
//     _value = [_someHash, _key] invoke(HashGet)
//

func(HashGet) = {
    (arg(0) select 0) getVariable arg(1);
};

//
// Function func(HashExist)
// Syntax:
//     _isKeyAExist = [_someHash, "keyA"] invoke(HashExist)
//

func(HashExist) = {
    !isNil func(HashGet);
};

//
// Function func(HashRemoveKey)
// Syntax:
//     [_someHash, _someKey] invoke(HashRemoveKey)
//

func(HashRemoveKey) = {
    private ["_hash", "_key"];
    _hash = arg(0);
    _key = arg(1);
    (_hash select 0) setVariable [_key, nil];
    _hash set [1, (_hash select 1) - [_key]];
};

//
// Function func(HashKeys)
// Syntax:
//     _keys = _someHash invoke(HashKeys);
//

func(HashKeys) = {
    +arg(1);
};

//
// Function func(HashValues)
// Syntax:
//     _values = _someHash invoke(HashValues);
//

func(HashValues) = {
    private "_values";
    _values = [];
    {
        _values set [count _values, [_this, _x] invoke(HashGet)]
    } foreach (_this invoke(HashKeys));
    _values
};


