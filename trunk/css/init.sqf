// SQF
//
// sqf-library "\css\init.sqf"
// Copyright (c) 2009-2010 Denis Usenko (DenVdmj)
// MIT-style license
//

if ( isNil {missionNamespace getVariable "/CSS/IsPresent"} ) then {
    missionNamespace setVariable ["/CSS/IsPresent", "Бдыщщ!"];
    private "_cssLibPath";
    _cssLibPath = ((if (isClass (configFile >> "CfgPatches" >> "css_lib")) then {"\"} else {""}) + "css\");
    { call compile preprocessFileLineNumbers (_cssLibPath + _x) } foreach [
        "lib\arrays.sqf",
        "lib\conf.sqf",
        "lib\date.sqf",
        "lib\geo.sqf",
        "lib\gui.sqf",
        "lib\strings.sqf",
        "lib\vectors.sqf",
        "lib\vehicles.sqf"
    ];
};
