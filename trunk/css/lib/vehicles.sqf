// SQF
//
// sqf-library "\css\lib\vehicles.sqf"
// Copyright (c) 2009-2010 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"

func(ArmAs) = {
    private ["_unit","_donor","_coef"];
    _unit = arg(0);
    _coef = argOr(2,1);
    _donor = configFile >> "CfgVehicles" >> arg(1);
    removeAllWeapons _unit;
    {
        for "" from 1 to ((_x select 1) * _coef) do {
            _unit addMagazine (_x select 0)
        };
    } foreach ( getArray ( _donor >> "magazines" ) invoke(List2Set) );
    {
        _unit addWeapon _x
    } foreach getArray (_donor >> "weapons");
};

// 
// func(CreateCustomVehicle)
// Syntax:
//     [
//         String vehicleType,
//         String special,
//         Position position,
//         Side or Group or Object group,
//         Array of String crewSlots,
//         Array of Soldiers unitList
//     ] invoke(CreateCustomVehicle)
//
// Arguments:
//     vehicleClass  —  the vehicle class.
//     special       —  create vehicle in the air or on the land, possable values: "NONE" (or ""), "FLY".
//     position      —  position of the vehicle.
//     group         —  group of the vehicle crew,
//                      if the soldier - will be used his group
//                      if the side - will create a new group by this side
//                      if the other value (eg 0 or "" or "default"), will create a new group
//                      owned by a native side of the vehicle.
//     crewSlots     —  bring the crew up to strength. А list containing some of the following
//                      values: "commander", "driver", "gunner", "cargo".
//     unitList      —  if present — crewmans will be retrieved one by one from this list,
//                      else — crewmans will be created.
//
// Example:
//     [
//         "RHIB",
//         "none",
//         screenToWorld [.5, .5],
//         west,
//         ["driver", "gunner"]
//     ] call css_func_CreateCustomVehicle
//

func(CreateCustomVehicle) = {
    private [
        "_vehicleType", "_position", "_group",
        "_crewSlots", "_getNextUnit", "_unitList",
        "_unitIndex", "_crewType", "_vehicle", "_moveIn"
    ];
    _vehicleType = arg(0);
    _position = arg(2);
    _group = argOr(3, 0) call {
        switch ( typeName _this ) do {
            case "GROUP" : { _this };
            case "OBJECT" : { group _this };
            case "SIDE" : { createGroup createCenter _this };
            default {
                createGroup createCenter (
                    [
                        east, west, resistance, civilian, nil, enemy, friendly, nil
                    ] select getNumber (
                        configFile >> "CfgVehicles" >> _vehicleType >> "side"
                    )
                )
            }
        }
    };
    _crewSlots = argSafeType(4, "array") else {
        ["commander", "driver", "gunner", "cargo"]
    };
    _getNextUnit = argIf(5) then {
        _unitList = arg(5);
        _unitIndex = -1;
        {
            if (INC(_unitIndex) < count _unitList) then {
                _unitList select _unitIndex
            }
        }
    } else {
        _crewType = getText (configFile >> "CfgVehicles" >> _vehicleType >> "crew");
        {
            _crewType createUnit [_position, _group, "", .7];
            units _group select ((count units _group)-1)
        }
    };
    _vehicle = createVehicle [_vehicleType, _position, [], 0, arg(1)];
    {
        _moveIn = (switch (toLower(_x)) do {
            case "commander" : {{ _this moveInCommander _vehicle }};
            case "driver"    : {{ _this moveInDriver _vehicle }};
            case "gunner"    : {{ _this moveInTurret [_vehicle, [_pos]] }};
            case "cargo"     : {{ _this moveInCargo _vehicle }};
            default { diag_log "error in func(CreateCustomVehicle), cargo type mismatch"; {} }
        });
        for "_pos" from 0 to (_vehicle emptyPositions _x) - 1 do {
            call _getNextUnit call _moveIn
        }
    } foreach _crewSlots;
    _vehicle
};

