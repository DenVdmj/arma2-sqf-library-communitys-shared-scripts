// SQF
//
// sqf-library "\css\init.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

if (isNil { missionNamespace getVariable "/CSS/IsPresent" }) then {
    missionNamespace setVariable ["/CSS/IsPresent", "Бдыщщ!"];
    (
        if (isClass (configFile >> "CfgPatches" >> "css_lib")) then {
            "\css\lib\"
        } else {
            "css\"
        }
    ) call {
        {
            call compile preprocessFileLineNumbers (_this + _x)
        } foreach [
            "arrays.sqf",
            "common.sqf",
            "conf.sqf",
            "date.sqf",
            "geo.sqf",
            "gui.sqf",
            "hashes.sqf",
            "mp.sqf",
            "strings.sqf",
            "vectors.sqf",
            "vehicles.sqf"
        ];
    }
};
