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

/*
func(CreateCustomVehicle)
    Создает технику
    Синтаксис:
        [
            string vehicleType,
            string special,
            position position,
            side or group or object group,
            array of string crewSlots,
            array of soldiers unitList
        ] call funcCreateVehicle

    vehicleType --  тип создаваемой техники
    special     --  возможные значения: "NONE" (или ""), "FLY"
    position    --  позиция в которой создается техника
    group       --  группа которой будет принадлежать экипаж созданной техники,
                    если указан юнит -- экипаж будет принадлежать его группе,
                    если указана сторона -- будет создана новая группа с указанной строной,
                    если укзано другое значение (например 0 или "" или "default" или не указано), для экипажа будет создана
                    новая группа принадлежащая стороне специфичной для данной техники
    crewSlots   --  комплектация экипажа, массив содержащий некоторые из следующих значений: "commander", "driver", "gunner", "cargo".
                    (создавать (если не задан пятый параметр) и помещать в технику: командира, водителя/пилота, пулеметчика/пулеметчиков, пассажиров)
    unitList    --  если задан -- юниты экипажа будут браться по очереди из данного списка
*/

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
        _crewType = getText( configFile >> "CfgVehicles" >> _vehicleType >> "crew" );
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

