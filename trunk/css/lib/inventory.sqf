// SQF
//
// sqf-library "\css\lib\inventory.sqf"
// Copyright (c) 2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

func(InvUnpackSlots) = {
    def(_slotsTable) = [];
    {
        _slotsTable set [_forEachIndex, floor (_this / (_x select 0)) % (_x select 1)];
    } foreach [[1,2],[2,2],[4,2],[16,16],[256,16],[4096,8],[65536,2],[131072,16]];
    _slotsTable;
};

func(InvGetSuperfluousSlots) = {
    private ["_unit", "_unitProvidedSlots", "_calcSuperfluous"];
    _unit = _this;
    _unitProvidedSlots = getNumber (configFile >> "CfgVehicles" >> typeOf _unit >> "weaponSlots");
    _calcSuperfluous = {
        private [
            "_itemsList", "_cfgSection", "_freeSlotsTable", "_superfluous",
            "_requiredSlotsTable", "_isSuperfluous", "_freeSlots"
        ];
        _itemsList = arg(0);
        _cfgSection = configFile >> arg(1);
        _freeSlotsTable = _unitProvidedSlots invoke(InvUnpackSlots);
        _superfluous = [];
        {
            _requiredSlotsTable = getNumber (_cfgSection >> _x >> "type") invoke(InvUnpackSlots);
            _isSuperfluous = false;
            for "_i" from 0 to count _requiredSlotsTable -1 do {
                _freeSlots = (_freeSlotsTable select _i) - (_requiredSlotsTable select _i);
                _freeSlotsTable set [_i, _freeSlots];
                if (_freeSlots < 0) then {
                    _isSuperfluous = true;
                };
            };
            if (_isSuperfluous) then {
                __push(_superfluous, _x);
            };
        } foreach _itemsList;
        _superfluous
    };
    [
        [weapons _unit, "CfgWeapons"] call _calcSuperfluous,
        [magazines _unit, "CfgMagazines"] call _calcSuperfluous
    ]
};
