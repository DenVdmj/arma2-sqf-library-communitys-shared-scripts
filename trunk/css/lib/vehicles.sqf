// SQF
//
// sqf-library "\css\lib\vehicles.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

//
// Function func(ArmAs)
// Syntax:
//     [object soldier, string donorClassName <, number fillCoeff>] invoke(ArmAs)
//

func(ArmAs) = {
    private ["_unit", "_donor", "_coef"];
    _unit = arg(0);
    _donor = configFile >> "CfgVehicles" >> arg(1);
    _coef = argOr(2,1);
    removeAllWeapons _unit;
    {
        for "" from 1 to ((_x select 1) * _coef) do {
            _unit addMagazine (_x select 0)
        };
    } foreach (getArray (_donor >> "magazines") invoke(List2Set));
    {
        _unit addWeapon _x
    } foreach getArray (_donor >> "weapons");
    _unit selectWeapon primaryWeapon _unit;
};

//
// Function func(CreateCustomVehicle)
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
//                      if the soldier—will be used his group
//                      if the side—will create a new group by this side
//                      if the other value (eg 0 or "" or "default"), will create a new group
//                      owned by a native side of the vehicle.
//     crewSlots     —  bring the crew up to strength. An list containing some of the following
//                      values: "commander", "driver", "gunner", "cargo".
//     unitList      —  if present—crewmans will be retrieved one by one from this
//                      list, else—crewmans will be created.
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
        "_vehicleType", "_position", "_vehicleDefaultSide", "_group", "_crewSlots",
        "_getNextUnit", "_unitList", "_unitIndex", "_crewType", "_vehicle", "_funcMoveIn"
    ];

    _vehicleType = arg(0);
    _position = arg(2);

    _vehicleDefaultSide = [
        east, west, resistance, civilian, nil, sideEnemy, sideFriendly, nil
    ] select getNumber (
        configFile >> "CfgVehicles" >> _vehicleType >> "side"
    );

    _group = argOr(3, 0) call {
        switch (typeName _this) do {
            case "GROUP" : { _this };
            case "OBJECT" : { group _this };
            case "SIDE" : { createGroup createCenter _this };
            default { createGroup createCenter _vehicleDefaultSide };
        }
    };

    _crewSlots = argIfType(4, "array") else {
        ["commander", "driver", "gunner", "cargo"]
    };

    _getNextUnit = ifExistArg(5) then {
        // If specified unit list -- gets units from list
        _unitList = arg(5);
        _unitIndex = -1;
        // Returns anonimous function
        {
            if (__inc(_unitIndex) < count _unitList) then {
                _unitList select _unitIndex
            }
        }
    } else {
        _crewType = getText (configFile >> "CfgVehicles" >> _vehicleType >> "crew");
        // New syntax of createUnit faster, but not able to create units to the other side
        if (_vehicleDefaultSide != side _group) then {
            // Returns anonimous function
            {
                _crewType createUnit [_position, _group, "", .7];
                units _group select ((count units _group)-1)
            }
        } else {
            // Returns anonimous function
            {
                _group createUnit [_crewType, _position, [], 0, ""];
            }
        }
    };
    _vehicle = createVehicle [_vehicleType, _position, [], 0, arg(1)];
    {
        _funcMoveIn = (switch (toLower(_x)) do {
            case "commander" : {{ _this moveInCommander _vehicle }};
            case "driver"    : {{ _this moveInDriver _vehicle }};
            case "gunner"    : {{ _this moveInTurret [_vehicle, [_pos]] }};
            case "cargo"     : {{ _this moveInCargo _vehicle }};
            default { "Cargo type mismatch!" __errorLog; {} }
        });
        for "_pos" from 0 to (_vehicle emptyPositions _x) - 1 do {
            call _getNextUnit call _funcMoveIn
        }
    } foreach _crewSlots;
    _vehicle
};
