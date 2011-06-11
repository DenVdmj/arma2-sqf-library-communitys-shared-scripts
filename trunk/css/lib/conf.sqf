// SQF
//
// sqf-library "\css\lib\conf.sqf"
// Copyright (c) 2009-2010 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"

func(ReadSlots) = { getNumber ( configFile >> "CfgVehicles" >> _this >> "weaponSlots" ) };
func(ReadSlotPrimary)     = { (_this invoke(ReadSlots)) % 2 };
func(ReadSlotHandGun)     = { floor((_this invoke(ReadSlots)) / 2 ) % 2 };
func(ReadSlotSecondary)   = { floor((_this invoke(ReadSlots)) / 4 ) % 2 };
func(ReadSlotHandGunMag)  = { floor((_this invoke(ReadSlots)) / 16 ) % 16 };
func(ReadSlotMag)         = { floor((_this invoke(ReadSlots)) / 256 ) % 16 };
func(ReadSlotGoggle)      = { floor((_this invoke(ReadSlots)) / 4096 ) % 8 };
func(ReadSlotHardMounted) = { floor((_this invoke(ReadSlots)) / 65536 ) % 2 };
func(ReadSlotItem)        = { floor((_this invoke(ReadSlots)) / 131072 ) % 16 };

func(isInheritFrom) = {
    private ["_curr", "_parent", "_void"];
    _curr = _this select 0;
    _parent = _this select 1;
    _void = configFile >> "*";
    while { true }  do {
        if (_curr == _void) exitwith { false };
        if (_curr == _parent) exitwith { true };
        _curr = inheritsFrom _curr;
    };
};

func(ConfigAmmo) = {
    configFile >> "CfgAmmo" >> (
        getText ( configFile >> "CfgMagazines" >> _this >> "ammo" )
    )
};

func(ReadOverlaying) = {
    private ["_class", "_overlayingClasses"];
    _class = arg(0) call {
        if (IS_CONF(_this)) then { _this } else { configFile >> "CfgWeapons" >> _this }
    };
    _overlayingClasses = [];
    {
        push(_overlayingClasses, if (_x == "this") then { _class } else { _class >> _x })
    } foreach getArray (_class >> arg(1));
    _overlayingClasses
};

func(ReadModes) = { [_this, "modes"] invoke(ReadOverlaying) };

func(ReadMuzzles) = { [_this, "muzzles"] invoke(ReadOverlaying) };

func(FilterWeapon) = {
    private [
        "_weaponFilter", "_weaponFound", "_ammoFilter", "_ammoFound",
        "_weapon", "_muzzle", "_magazine", "_ammo",
        "_result", "_muzzles", "_magazines",
        "_weaponFormat", "_muzzleFormat", "_ammoFormat"
    ];

    _result = [];
    _weaponFilter = { true };
    _weaponFormat = { [_weapon, _muzzles] };
    _muzzleFormat = { [_muzzle, _magazines] };
    _ammoFormat = { [_magazine, _ammo] };
    _ammoFound = {
        push(_magazines, call _ammoFormat);
    };
    call arg(1);

    if (isNil "_weaponFound") then {
        _weaponFound = (
            if (isNil "_ammoFilter") then {{
                push(_muzzles, [_muzzle]);
            }} else {{
                _magazines = [];
                {
                    _magazine = configFile >> "CfgMagazines" >> _x;
                    _ammo = _x invoke(ConfigAmmo);
                    if (call _ammoFilter) then _ammoFound;
                } foreach getArray ( _x >> "magazines" );
                if (count _magazines > 0) then {
                    push(_muzzles, call _muzzleFormat);
                };
            }}
        );
    };

    try {
        {
            _weapon = _x;
            _muzzles = [];
            {
                _muzzle = _x;
                if call _weaponFilter then _weaponFound;
            } foreach (_weapon invoke(ReadMuzzles));
            if (count _muzzles > 0) then {
                push(_result, call _weaponFormat);
            };
        } foreach (
            arg(0) call {
                switch (typeName _this) do {
                    case "OBJECT" : func(GetUnitWeaponsExt);
                    case "ARRAY" : { _this };
                    case "STRING" : { [_this] };
                    default {
                        [configFile >> "CfgWeapons", {
                            if isClass _x then { configName _x }
                        }] invoke(MapGrep)
                    };
                };
            }
        );
        _result
    } catch { _exception }
};

func(ReadAnyMagazines) = {
    private "_mags";
    _mags = [];
    {
        _mags = _mags + getArray ( _x >> "magazines" )
    } foreach (_this invoke(ReadMuzzles));
    _mags
};

#define __SDFireLightIntensity .001
#define __SDAudibleFire .1
#define __isWeaponSD(M) (getNumber((M) >> "fireLightIntensity") < __SDFireLightIntensity)
#define __isAmmoSD(A) (getNumber((A) >> "audibleFire") < __SDAudibleFire)

func(IsMagazineSD) = {
    __isAmmoSD(_this invoke(ConfigAmmo))
};

func(IsWeaponSD) = {
    [ _this, {
        _result = false;
        _weaponFilter = { __isWeaponSD(_muzzle) };
        _ammoFilter = { __isAmmoSD(_ammo) };
        _ammoFound = { throw true };
    }] invoke(FilterWeapon)
};

func(FilterWeaponSDSense) = {
    private ["_weaponSD", "_ammoSD"];
    [ _this, {
        _weaponFilter = {
            _weaponSD = __isWeaponSD(_muzzle);
            true
        };
        _ammoFilter = {
            _ammoSD = __isAmmoSD(_ammo);
            !XOR(_weaponSD, _ammoSD)
        };
    }] invoke(FilterWeapon)
};

func(FilterWeaponSD) = {
    [ _this, {
        _weaponFilter = { __isWeaponSD(_muzzle) };
        _ammoFilter = { __isAmmoSD(_ammo) };
    }] invoke(FilterWeapon)
};

func(FilterATGun) = {
    [ _this, {
        _ammoFilter = {
            getText ( _ammo >> "simulation" ) in [
                "shotMissile", "shotRocket",
                "shotBullet", "shotShell"
            ] &&
            getNumber ( _ammo >> "hit" ) > 70
        }
    }] invoke(FilterWeapon)
};

func(FilterAAGun) = {
    [ _this, {
        _ammoFilter = {
            getText ( _ammo >> "simulation" ) in ["shotMissile", "shotRocket"] &&
            getNumber ( _ammo >> "irLock" ) == 1
        }
    }] invoke(FilterWeapon)
};

func(FilterFirearm) = {
    [ _this, {
        _ammoFilter = {
            getText ( _ammo >> "simulation" ) == "shotBullet"
        }
    }] invoke(FilterWeapon)
};

func(ReadActions) = {
    private "_moves";
    _moves = configFile >> getText ( configFile >> "CfgVehicles" >> arg(0) >> "moves" );
    _moves >> "Actions" >> getText ( _moves >> "States" >> arg(1) >> "actions" )
};

func(ReadUpDegree) = {
    getNumber ( [typeOf _this, animationState _this] invoke(ReadActions) >> "upDegree" )
};

func(ReadAnimType) = {
    getText ( [typeOf _this, animationState _this] invoke(ReadActions) >> "upDegree" )
};

func(ReadWeaponType) = {
    getNumber ( configFile >> "CfgWeapons" >> _this >> "type" )
};

func(ReadMagazineType) = {
    getNumber ( configFile >> "CfgMagazines" >> _this >> "type" )
};

func(WeaponInHand) = {
    private ["_upDegree", "_weapon"];
    _weapon = currentWeapon _this;
    if (_weapon != "") exitwith { _weapon };
    _upDegree = _this invoke(ReadUpDegree);
    {
        if (_upDegree in (
            switch (_x invoke(ReadWeaponType)) do {
                case 1: {[6, 8, 10, 4]};    // primary weapon
                case 5: {[6, 8, 10, 4]};    // and maschinegun also (primary and secondary weapon slot)
                case 2: {[9, 5, 7]};        // handgun slot
                case 4: {[1]};              // secondary weapon slot
                case 4096: {[2, 13, 14]};   // goggle slot
                default {[]};
            }
        )) exitwith { _x }; ""
    } foreach weapons _this
};

func(GetWeaponByTypes) = {
    private "_types";
    _types = arg(1);
    {
        if (_x invoke(ReadWeaponType) in _types) exitwith { _x }; "";
    } foreach (arg(0) call {
        switch (typeName _this) do {
            case "ARRAY" : { _this };
            case "OBJECT" : func(GetUnitWeaponsExt);
            default { [] };
        }
    });
};

func(GetTurretsWeapons) = {
    private ["_weapons", "_findRecurse"];
    _weapons = [];
    _findRecurse = {
        for "_i" from 0 to count _this -1 do {
            (_this select _i) call {
                if (isClass _this) then {
                    _weapons = _weapons + getArray ( _this >> "weapons" );
                    (_this >> "turrets") call {
                        if (isClass _this) then _findRecurse;
                    };
                };
            };
        };
    };
    (
        configFile >> "CfgVehicles" >> (
            switch (typeName _this) do {
                case "STRING" : {_this};
                case "OBJECT" : {typeof _this};
                default {nil};
            }
        ) >> "turrets"
    ) call _findRecurse;
    _weapons;
};

func(GetUnitWeaponsExt) = if (count supportInfo "*:getweaponcargo*" != 0) then {{
    (weapons _this) + (getWeaponCargo _this select 0)
}} else {{
    (weapons _this)
}};
