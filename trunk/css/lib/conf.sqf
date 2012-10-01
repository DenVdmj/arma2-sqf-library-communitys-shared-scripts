// SQF
//
// sqf-library "\css\lib\conf.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#include "\css\config.macro"

#define __PATH__ \css\lib

#define __readSlots(class) (getNumber (configFile >> "CfgVehicles" >> (class) >> "weaponSlots"))

//
// Function func(ReadSlotPrimary)
// Function func(ReadSlotHandGun)
// Function func(ReadSlotSecondary)
// Function func(ReadSlotHandGunMag)
// Function func(ReadSlotMag)
// Function func(ReadSlotGoggle)
// Function func(ReadSlotHardMounted)
// Function func(ReadSlotItem)
//
// Syntax:
//     (string vehicleClassName) invoke(ReadSlot<SlotName>)
// Returns the number of (respectively) slots available vehicleClassName.
//

func(ReadSlotPrimary)     = { __readSlots(_this) % 2 };
func(ReadSlotHandGun)     = { floor(__readSlots(_this) / 2 ) % 2 };
func(ReadSlotSecondary)   = { floor(__readSlots(_this) / 4 ) % 2 };
func(ReadSlotHandGunMag)  = { floor(__readSlots(_this) / 16 ) % 16 };
func(ReadSlotMag)         = { floor(__readSlots(_this) / 256 ) % 16 };
func(ReadSlotGoggle)      = { floor(__readSlots(_this) / 4096 ) % 8 };
func(ReadSlotHardMounted) = { floor(__readSlots(_this) / 65536 ) % 2 };
func(ReadSlotItem)        = { floor(__readSlots(_this) / 131072 ) % 16 };

//
// Function func(IsInheritFrom)
// Syntax:
//     [config someConfHandle, config theParentConfHandle] invoke(IsInheritFrom)
// Returns the true if someConfHandle is a subclass of theParentConfHandle.
//
// Example 1:
//     [
//         configFile >> "CfgWeapons" >> primaryWeapon player,
//         configFile >> "CfgWeapons" >> "RifleCore"
//     ] invoke(IsInheritFrom);
//
// Example 2:
//     [
//         configFile >> "CfgWeapons" >> primaryWeapon player,
//         configFile >> "CfgWeapons" >> "MissileCore"
//     ] invoke(IsInheritFrom)
//

func(IsInheritFrom) = {
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

//
// Function func(ConfigAmmo)
// Syntax:
//     (string magazineClassName) invoke(ConfigAmmo)
// Returns the entrypoint of CfgAmmo for the specified magazine. Config type.
//

func(ConfigAmmo) = {
    configFile >> "CfgAmmo" >> (
        getText ( configFile >> "CfgMagazines" >> _this >> "ammo" )
    )
};

//
// Function func(ReadOverlaying)
// Syntax:
//     [string weaponClassName, overlayingClassName] invoke(ReadOverlaying)
//     [config weaponClassEntryPoint, "modes"] invoke(ReadOverlaying)
// Read overlaying classes. Inside function.
//

func(ReadOverlaying) = {
    private ["_class", "_overlayingClasses"];
    _class = arg(0) call {
        if (__isConfig(_this)) then { _this } else { configFile >> "CfgWeapons" >> _this }
    };
    _overlayingClasses = [];
    {
        __push(_overlayingClasses, if (_x == "this") then { _class } else { _class >> _x })
    } foreach getArray (_class >> arg(1));
    _overlayingClasses
};

//
// Function func(ReadModes)
// Syntax:
//     (string weaponClassName) invoke(ReadModes)
//     (config weaponClassEntryPoint) invoke(ReadModes)
// Returns an array of entry points into the "modes". Array of config.
//

func(ReadModes) = { [_this, "modes"] invoke(ReadOverlaying) };

//
// Function func(ReadMuzzles)
// Syntax:
//     (string weaponClassName) invoke(ReadMuzzles)
//     (config weaponClassEntryPoint) invoke(ReadMuzzles)
// Returns an array of entry points into weapon's muzzles. Array of config.
// Example of func(ReadModes) and func(ReadMuzzles):
//     // correct reading of the properties of weapons (it real value of dispersion)
//     hint str getNumber (
//         ((primaryWeapon player invoke(ReadMuzzles) select 0) invoke(ReadModes) select 0) >> "dispersion"
//     );
//
//     // the most accurate of all available muzzles
//     _dispersion = 1e40; // 1.#INF
//     {
//         {
//             _dispersion = _dispersion min getNumber (_x >> "dispersion")
//         } foreach (_x invoke(ReadModes))
//     } foreach (primaryWeapon player invoke(ReadMuzzles));
//
//     hint str _dispersion;
//

func(ReadMuzzles) = { [_this, "muzzles"] invoke(ReadOverlaying) };

//
// Function func(FilterWeapon)
// Syntax:
//     [
//         string weaponClassName or
//         array of string listOfWeaponClassNames or
//         object soldier or
//         otherType value,
//         {
//             declarative query
//         }
//     ] invoke(FilterWeapon)
//
// Filters an array of weapons with custom conditions. (for more, see. "en.funcFilterWeapon.readme.txt")
// First and foremost this function is base for such functions as:
//   func(FilterWeaponSD), func(FilterATGun), func(FilterAAGun)
// Example:
//
//     Search all weapon with ammo with simulation == shotRocket:
//     [player, { _ammoFilter = {
//         getText (_ammo >> "simulation") == "shotRocket"
//     }}] invoke(FilterWeapon)
//
//     Result:
//     [ // weapon list
//         ["SMAW", // weapon classname
//             [ // muzzle list
//                 [/CfgWeapons/SMAW", // muzzle
//                     [ // ammolist, list of pairs: magazine configEntry & ammo configEntry
//                         [/CfgMagazines/SMAW_HEAA, /CfgAmmo/R_SMAW_HEAA],
//                         [/CfgMagazines/SMAW_HEDP, /CfgAmmo/R_SMAW_HEDP]
//                     ]
//                 ]
//             ]
//         ]
//     ]
//

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
        __push(_magazines, call _ammoFormat);
    };
    call arg(1);

    if (isNil "_weaponFound") then {
        _weaponFound = (
            if (isNil "_ammoFilter") then {{
                __push(_muzzles, [_muzzle]);
            }} else {{
                _magazines = [];
                {
                    _magazine = configFile >> "CfgMagazines" >> _x;
                    _ammo = _x invoke(ConfigAmmo);
                    if (call _ammoFilter) then _ammoFound;
                } foreach getArray ( _x >> "magazines" );
                if (count _magazines > 0) then {
                    __push(_muzzles, call _muzzleFormat);
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
                __push(_result, call _weaponFormat);
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

//
// Function func(ReadAnyMagazines)
// Syntax:
//     (string weaponClassName) invoke(ReadAnyMagazines)
// Return all compatibles magazines. Array of string.
// Example:
//     "m16a4" invoke(ReadAnyMagazines);
//     result:
//     [
//         "30Rnd_556x45_Stanag",
//         "30Rnd_556x45_StanagSD",
//         "20Rnd_556x45_Stanag",
//         "30Rnd_556x45_G36",
//         "100Rnd_556x45_BetaCMag",
//         "30Rnd_556x45_G36SD"
//     ]
//

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

//
// Function func(IsMagazineSD)
// Syntax:
//     (string MagazineName) invoke(IsMagazineSD)
// Returns true if the magazine uses noiseless ammo.
//

func(IsMagazineSD) = {
    __isAmmoSD(_this invoke(ConfigAmmo))
};

//
// Function func(IsWeaponSD)
// Syntax:
//     (string weaponClassName) invoke(IsWeaponSD)
//     (array of string listOfWeaponClassNames) invoke(IsWeaponSD)
//     (object soldier) invoke(IsWeaponSD)
// Returns true if the weapon has a small flash and uses a noiseless ammo.
// Note: If the soldier, there will be a used list of weapons used by the soldier.
//
// Example:
//
//     // true if is the primary weapon with the suppressor
//     primaryWeapon player invoke(IsWeaponSD)
//
//     // true if player has weapon with the suppressor
//     weapons player invoke(IsWeaponSD)
//

func(IsWeaponSD) = {
    [ _this, {
        _result = false;
        _weaponFilter = { __isWeaponSD(_muzzle) };
        _ammoFilter = { __isAmmoSD(_ammo) };
        _ammoFound = { throw true };
    }] invoke(FilterWeapon)
};

//
// Function func(FilterWeaponSDSense)
// Syntax:
//     (string weaponClassName) invoke(FilterWeaponSDSense)
//     (array of string listOfWeaponClassNames) invoke(FilterWeaponSDSense)
//     (object unit) invoke(FilterWeaponSDSense)
//     (otherType value) invoke(FilterWeaponSDSense)
// Returns are compatible magazines in the form of an array:
//     [ // weaponlist
//         [weapon classname, // pair: weapon & muzzlelist
//             [ // muzzlelist
//                 [muzzle configEntry, // pair: muzzle & ammolist
//                     [ // ammolist
//                         [magazine configEntry, ammo configEntry],
//                         [magazine configEntry, ammo configEntry]
//                     ]
//                 ]
//             ]
//         ],
//         [weapon classname,
//             [
//                 [muzzle configEntry,
//                     [
//                         [magazine configEntry, ammo configEntry],
//                         [magazine configEntry, ammo configEntry]
//                     ]
//                 ]
//             ]
//         ],
//         etc.
//     ]
// Note: If the unit, there will be a used list of weapons used by the unit.
// Note: If the "other type value", there will be a used list of all weapons, that presented in game.
// Note: SD-sensitive, suppressed ammo are returned only for weapons (muzzles) of a small flash, and
//       vice versa — for such guns are returned only suppressed ammo.
//

func(FilterWeaponSDSense) = {
    private ["_weaponSD", "_ammoSD"];
    [ _this, {
        _weaponFilter = {
            _weaponSD = __isWeaponSD(_muzzle);
            true
        };
        _ammoFilter = {
            _ammoSD = __isAmmoSD(_ammo);
            !__xor(_weaponSD, _ammoSD)
        };
    }] invoke(FilterWeapon)
};

//
// Function func(FilterWeaponSD)
// Syntax:
//     (string weaponClassName) invoke(FilterWeaponSD)
//     (array of string listOfWeaponClassNames) invoke(FilterWeaponSD)
//     (object soldier) invoke(FilterWeaponSD)
//     (otherType value) invoke(FilterWeaponSD)
// Search (in listOfWeaponClassNames) SD weapons (has a small flash and uses a noiseless ammo), search
// result is returned as an array of formats.
// Note: If the soldier, there will be a used list of weapons used by the soldier.
// Note: If the "other type value", there will be a used list of all weapons, that presented in game.
//
// Example:
//     player invoke(FilterWeaponSD)
//     Result:
//     [
//         ["M9SD",
//             [
//                 [/CfgWeapons/M9SD,
//                     [
//                         [/CfgMagazines/15Rnd_9x19_M9SD, /CfgAmmo/B_9x19_SD]
//                     ]
//                 ]
//             ]
//         ],
//         ["M4A1_AIM_SD_camo",
//             [
//                 [/CfgWeapons/M4A1_AIM_SD_camo,
//                     [
//                         [/CfgMagazines/30Rnd_556x45_StanagSD, /CfgAmmo/B_556x45_SD],
//                         [/CfgMagazines/30Rnd_556x45_G36SD, /CfgAmmo/B_556x45_SD]
//                     ]
//                 ]
//             ]
//         ]
//     ]
//     // get all sd-weapons from game config
//     0 invoke(FilterWeaponSD)
//

func(FilterWeaponSD) = {
    [ _this, {
        _weaponFilter = { __isWeaponSD(_muzzle) };
        _ammoFilter = { __isAmmoSD(_ammo) };
    }] invoke(FilterWeapon)
};

//
// Function func(FilterATGun)
// Syntax:
//     (string WeaponClassName) invoke(FilterATGun)
//     (array of string listOfWeaponClassNames) invoke(FilterATGun)
//     (object soldier) invoke(FilterATGun)
//     (otherType value) invoke(FilterATGun)
// Search (in listOfWeaponClassNames) weapons capable of hitting a tank. Output format is similar
// to the output format of the function FilterWeaponSD.
// Note: If the soldier, there will be a used list of weapons used by the soldier.
// Note: If the "other type value", there will be a used list of all weapons, that presented in game.
//

func(FilterATGun) = {
    [ _this, {
        _ammoFilter = {
            toLower getText ( _ammo >> "simulation" ) in [
                "shotmissile", "shotrocket",
                "shotbullet", "shotshell"
            ] &&
            getNumber ( _ammo >> "hit" ) > 70
        }
    }] invoke(FilterWeapon)
};

//
// Function func(FilterAAGun)
// Syntax:
//     (string WeaponClassName) invoke(FilterAAGun)
//     (array of string listOfWeaponClassNames) invoke(FilterAAGun)
//     (object unit) invoke(FilterAAGun)
//     (otherType value) invoke(FilterAAGun)
//
// Search (in listOfWeaponClassNames) weapons homing (irLock). Output format is
// similar to the output format of the function FilterWeaponSD.
// Note: If the soldier, there will be a used list of weapons used by the soldier.
// Note: If the "other type value", there will be a used list of all weapons, that presented in game.
//

func(FilterAAGun) = {
    [ _this, {
        _ammoFilter = {
            toLower getText ( _ammo >> "simulation" ) in ["shotmissile", "shotrocket"] &&
            getNumber ( _ammo >> "irLock" ) == 1
        }
    }] invoke(FilterWeapon)
};

//
// Function func(FilterFirearm)
// Syntax:
//     (string WeaponClassName) invoke(FilterFirearm)
//     (array of string listOfWeaponClassNames) invoke(FilterFirearm)
//     (object unit) invoke(FilterFirearm)
//     (otherType value) invoke(FilterFirearm)
//
// Search (in listOfWeaponClassNames) firearm weapons (weapons firing shotBullets). Output
// format is similar to the output format of the function FilterWeaponSD.
// Note: If the soldier, there will be a used list of weapons used by the soldier.
// Note: If the "other type value", there will be a used list of all weapons, that presented in game.
//

func(FilterFirearm) = {
    [ _this, {
        _ammoFilter = {
            getText ( _ammo >> "simulation" ) == "shotbullet"
        }
    }] invoke(FilterWeapon)
};

//
// Function func(ReadActions)
// Syntax:
//     [string unitClassName, string targetAnimation] invoke(ReadActions)
// Return the entrypoint to class Actions (configFile >> _unitClassNameMoves >> "Actions") for
// specified unitClassName and his targetAnimation.
// Example:
//     player playMove ([typeOf player, animationState player] invoke(ReadActions) >> "reloadMagazine")
//     // is the same as that:
//     player playAction "reloadMagazine"
//

func(ReadActions) = {
    private "_moves";
    _moves = configFile >> getText ( configFile >> "CfgVehicles" >> arg(0) >> "moves" );
    _moves >> "Actions" >> getText ( _moves >> "States" >> arg(1) >> "actions" )
};

//
// Function func(ReadUpDegree)
// Syntax:
//     (object soldier) invoke(ReadUpDegree)
// Returns the value of the property UpDegree (AI Animation State) of the animation for the
// specified unit. Number type.
// Possible values are defined in config game:
//     enum {
//         MANPOSLYINGBINOC = 2,
//         MANPOSSTANDBINOC = 14,
//         MANPOSDEAD = 0,
//         MANPOSLYINGRFL = 4,
//         MANPOSKNEELBINOC = 13,
//         MANPOSLYINGHND = 5,
//         MANPOSKNEELRFL = 6,
//         MANPOSSTANDRFL = 8,
//         MANPOSSTAND = 10,
//         MANPOSSWIMMING = 11,
//         MANPOSWEAPON = 1,
//         MANPOSKNEELHND = 7,
//         MANPOSSTANDHND = 9,
//         MANPOSLYINGCIVIL = 3,
//         MANPOSSTANDCIVIL = 12,
//     };
//
// Note: file "\css\config.macros" contains the following macros:
//     #define __ManPosLyingBinoc 2
//     #define __ManPosStandBinoc 14
//     #define __ManPosDead 0
//     etc.
//

func(ReadUpDegree) = {
    getNumber ( [typeOf _this, animationState _this] invoke(ReadActions) >> "upDegree" )
};

//
// Function func(ReadAnimType)
// Syntax:
//     (object soldier) invoke(ReadAnimType)
// Returns the type of the current animation. One of the following:
//     "ManPosDead"
//     "ManPosStand"
//     "ManPosCombat"
//     "ManPosCrouch"
//     "ManPosLying"
//     "ManPosHandGunStand"
//     "ManPosHandGunCrouch"
//     "ManPosHandGunLying"
//     "ManPosLyingNoWeapon"
//     "ManPosWeapon"
//     "ManPosNoWeapon"
//     "ManPosSwimming"
//     "ManPosBinoc"
//     "ManPosBinocLying"
//     "ManPosBinocStand"
//

func(ReadAnimType) = {
    getText ( [typeOf _this, animationState _this] invoke(ReadActions) >> "upDegree" )
};

//
// Function func(ReadWeaponType)
// Syntax:
//     (string weaponClassName) invoke(ReadWeaponType)
// Returns the type of the weapon slot. One of the following:
//     WeaponNoSlot            0   // Dummy weapons
//     WeaponSlotPrimary       1   // Primary weapon
//     WeaponSlotHandGun       2   // Handgun slot
//     WeaponSlotSecondary     4   // Secondary weapon (launcher)
//     WeaponSlotHandGunMag   16   // Handgun magazines (8x)(or grenades for M203/GP-25)
//     WeaponSlotMag         256   // Magazine slots (12x / 8x for medics)
//     WeaponSlotGoggle     4096   // Goggle slot (2x)
//     WeaponHardMounted   65536   // stationary weapons
//
// Note: file "\css\config.macros" contains the following macros:
//     #define __WeaponNoSlot 0
//     #define __WeaponSlotPrimary 1
//     #define __WeaponSlotHandGun 2
//     #define __WeaponSlotSecondary 4
//     etc.
//

func(ReadWeaponType) = {
    getNumber ( configFile >> "CfgWeapons" >> _this >> "type" )
};

//
// Function func(ReadMagazineType)
// Syntax:
//     (string magazineClassName) invoke(ReadMagazineType)
// Returns the type of the magazine slot. Possible types, see above.
//

func(ReadMagazineType) = {
    getNumber ( configFile >> "CfgMagazines" >> _this >> "type" )
};

//
// Function func(WeaponInHand)
// Syntax:
//     (object soldier) invoke(WeaponInHand)
// Returns weapons in the hands of soldiers. String type.
//

func(WeaponInHand) = {
    private ["_upDegree", "_weapon"];
    _weapon = currentWeapon _this;
    if (_weapon != "") exitwith { _weapon };
    _upDegree = _this invoke(ReadUpDegree);
    {
        if (_upDegree in (
        /*
            switch (_x invoke(ReadWeaponType)) do {
                case __WeaponSlotPrimary: {
                    [__ManPosCrouch, __ManPosCombat, __ManPosStand, __ManPosLying]
                };
                case __WeaponSlotMachinegun: {
                    [__ManPosCrouch, __ManPosCombat, __ManPosStand, __ManPosLying]
                };
                case __WeaponSlotHandGun: {
                    [__ManPosHandGunStand, __ManPosHandGunLying, __ManPosHandGunCrouch]
                };
                case __WeaponSlotSecondary: {
                    [__ManPosWeapon]
                };
                case __WeaponSlotGoggle: {
                    [__ManPosBinocLying, __ManPosBinoc, __ManPosBinocStand]
                };
                default {[]};
            }
        */
            (_x invoke(ReadWeaponType)) call {
                if (_this == __WeaponSlotPrimary || _this == __WeaponSlotMachinegun) exitwith {
                    [__ManPosCrouch, __ManPosCombat, __ManPosStand, __ManPosLying]
                };
                if (_this == __WeaponSlotHandGun) exitwith {
                    [__ManPosHandGunStand, __ManPosHandGunLying, __ManPosHandGunCrouch]
                };
                if (_this == __WeaponSlotSecondary) exitwith {
                    [__ManPosWeapon]
                };
                if (_this == __WeaponSlotGoggle) exitwith {
                    [__ManPosBinocLying, __ManPosBinoc, __ManPosBinocStand]
                };
                []
            }
        )) exitwith { _x };
        ""
    } foreach weapons _this
};

//
// Function func(CurrentMuzzle)
// Syntax:
//     (object soldier) invoke(CurrentMuzzle)
// Returns current muzzle of weapons in the hands of soldiers.
// if current muzzle is void string, returns the first muzzle of the current weapon. String type.
// This function workaround for currentMuzzle's bug when void string returns for yet no shooted AI
//

func(CurrentMuzzle) = {
    if (currentMuzzle _this != "") exitwith {
        currentMuzzle _this;
    };
    configName (((_this invoke(WeaponInHand)) invoke(ReadMuzzles)) select 0);
};

//
// Function func(GetWeaponByTypes)
// Syntax:
//     [array weaponsList, array weaponTypeList] invoke(GetWeaponByTypes)
//     [object soldier, array weaponTypeList] invoke(GetWeaponByTypes)
// Returns weapon with the specified weapon type. String type.
//

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

//
// Function func(GetTurretsWeapons)
// Syntax:
//     (object vehicle) invoke(GetTurretsWeapons)
//     (string vehicleClass) invoke(GetTurretsWeapons)
// Returns information about all weapons on turrets in an array of the following format:
//     [
//         [(string weaponClassName),
//             [ // magazines list
//                 (string magazineClassName),
//                 (string magazineClassName),
//                 etc.
//             ],
//             (array turretPath),
//             (config turretClass)
//         ],
//         etc.
//     ]
//
// Example:
//     // function works with objects
//     cursorTarget invoke(GetTurretsWeapons)
//
// Example:
//     // works with classnames too
//     "M1A2_US_TUSK_MG_EP1" invoke(GetTurretsWeapons)
//
// Result:
//   [
//     ["M256", ["20Rnd_120mmSABOT_M1A2", "20Rnd_120mmHE_M1A2"], [0], bin\config.bin/CfgVehicles/M1A2_US_TUSK_MG_EP1/Turrets/MainTurret],
//     ["M240_veh", ["100Rnd_762x51_M240", "1200Rnd_762x51_M240"], [0], bin\config.bin/CfgVehicles/M1A2_US_TUSK_MG_EP1/Turrets/MainTurret],
//     ["M2BC", ["100Rnd_127x99_M2"], [0, 0], bin\config.bin/CfgVehicles/M1A2_US_TUSK_MG_EP1/Turrets/MainTurret/Turrets/CommanderOptics],
//     ["SmokeLauncher", ["SmokeLauncherMag"], [0, 0], bin\config.bin/CfgVehicles/M1A2_US_TUSK_MG_EP1/Turrets/MainTurret/Turrets/CommanderOptics],
//     ["M240_veh_2", ["100Rnd_762x51_M240", "1200Rnd_762x51_M240"], [0, 1], bin\config.bin/CfgVehicles/M1A2_US_TUSK_MG_EP1/Turrets/MainTurret/Turrets/LoaderTurret]
//   ]
//

func(GetTurretsWeapons) = {
    private ["_result", "_findRecurse", "_class"];
    _result = [];
    _findRecurse = {
        private ["_root", "_class", "_path", "_currentPath"];
        _root = arg(0);
        _path = +arg(1);
        for "_i" from 0 to count _root -1 do {
            _class = _root select _i;
            if (isClass _class) then {
                _currentPath = _path + [_i];
                {
                    [_x, _x invoke(ReadAnyMagazines), _currentPath, _class] __pushTo(_result);
                } foreach getArray (_class >> "weapons");
                _class = _class >> "turrets";
                if (isClass _class) then {
                    [_class, _currentPath] call _findRecurse;
                };
            };
        };
    };
    _class = (
        configFile >> "CfgVehicles" >> (
            switch (typeName _this) do {
                case "STRING" : {_this};
                case "OBJECT" : {typeOf _this};
                default {nil}
            }
        ) >> "turrets"
    );
    [_class, []] call _findRecurse;
    _result;
};

//
// Function func(GetTurretPath)
// Syntax:
//     [string vehicleClassName, string weaponClassName] invoke(GetTurretPath)
// Returns first found turret path for specified weapon.
// example:
//     ["M1A2_US_TUSK_MG_EP1", "M240_veh_2"] invoke(GetTurretPath)
// result:
//     [0,1]
//

func(GetTurretPath) = {
    private ["_vehicleClass", "_weaponClass", "_findRecurse"];
    _vehicleClass = arg(0);
    _weaponClass = arg(1);
    _findRecurse = {
        private ["_root", "_path", "_class", "_currentPath"];
        _root = arg(0);
        _path = +arg(1);
        for "_i" from 0 to count _root -1 do {
            _class = _root select _i;
            if (isClass _class) then {
                _currentPath = _path + [_i];
                {
                    if (_weaponClass == _x) then {
                        throw _currentPath;
                    };
                } foreach getArray (_class >> "weapons");
                _class = _class >> "turrets";
                if (isClass _class) then {
                    [_class, _currentPath] call _findRecurse;
                };
            };
        };
    };
    try {
        [configFile >> "CfgVehicles" >> _vehicleClass >> "turrets", []] call _findRecurse;
        []; // default
    } catch {
        _exception
    };
};

func(GetUnitWeaponsExt) = if (count supportInfo "*:getweaponcargo*" != 0) then {{
    (weapons _this) + (getWeaponCargo _this select 0)
}} else {{
    (weapons _this)
}};
