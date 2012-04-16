#include "\css\css"

private "_hash";
private "_list";

_hash = "logic" createVehicleLocal [0,0,0];

_list = [
    configFile >> "CfgMovesBasic" >> "Actions",
    {
        if (isNil {_hash getVariable getText(_x >> "upDegree")}) then {
            _hash setVariable [getText(_x >> "upDegree"), true];
            private ["_name", "_value"];
            _value = getNumber(_x >> "upDegree");
            _name = if (_value < 0) then { "ManPosNoActions" } else { getText(_x >> "upDegree") };
            ["#define __" + _name + " " + str _value, _value];
        };
    }
] invoke(MapGrep);

deleteVehicle _hash;

private "_posList";
private "_numList";
private "_result";

_posList = { _x select 0 } MAP(_list);
_numList = { _x select 1 } MAP(_list);

[_numList, _posList] invoke(SortArray);

_result = [_posList, toString [0x0D, 0x0A]] invoke(JoinString);

copyToClipboard _result;

_result
