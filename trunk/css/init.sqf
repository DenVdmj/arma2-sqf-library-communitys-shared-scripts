// SQF
//
// sqf-library "\css\init.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

if ( isNil {missionNamespace getVariable "/CSS/IsPresent"} ) then {
    missionNamespace setVariable ["/CSS/IsPresent", "Бдыщщ!"];
    private "_cssLibPath";
    _cssLibPath = ((if (isClass (configFile >> "CfgPatches" >> "css_lib")) then {"\"} else {""}) + "css\lib\");
    { call compile preprocessFileLineNumbers (_cssLibPath + _x) } foreach [
        "arrays.sqf",
        "common.sqf",
        "conf.sqf",
        "date.sqf",
        "geo.sqf",
        "gui.sqf",
        "mp.sqf",
        "strings.sqf",
        "vectors.sqf",
        "vehicles.sqf"        
    ];
};
