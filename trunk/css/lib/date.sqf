// SQF
//
// sqf-library "\css\lib\date.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib
   
//
// Function func(GetDate)
// Syntax:
//     invoke(GetDate)
// Returns the current ingame date up to the 
// millisecond, an array in the following format:
//     [year, month, day, hour, minute, second, millisecond]
//

func(GetDate) = {
    date call {
        _this set [4, floor( 60 * dayTime % 60 )];
        _this set [5, floor( 3600 * dayTime % 60 )];
        _this set [6, floor( 216000 * dayTime % 60 )];
        _this;
    };
};

//
// Function func(SetDate)
// Syntax:
//     (date antDate) invoke(SetDate)
// Sets the current ingame date up to the millisecond.
// Note: date type—five- or seven-items array:
//     [year, month, day, hour, minute (, second, millisecond)]
//     

func(SetDate) = {
    +_this call {
        _this resize 5;
        setDate _this;
    };
    if (count _this > 5) then {
        skipTime ((_this select 5) / 3600);
        skipTime ((_this select 6) / 216000);
    };
};

//
// Function func(FormatDate)
// Syntax:
//     [array anyDate, string _format] invoke(SetDate)
//     [number dayTime, string _format] invoke(SetDate)    
//     [array anyDate] invoke(SetDate)
//     [number dayTime] invoke(SetDate)    
//
// Returns a formatted date-string.
// Note: anyDate can be five- or seven-items array:
//     [year, month, day, hour, minute (, second, millisecond)]
//
// You can use the following placeholders in the format string:
//     %1 — year
//     %2 — month number
//    %12 — month string (localized: "January", "Leden", "Januar", 
//           "Styczen", "Январь", "Janvier", "Enero", "Gennaio")
//    %22 — month string, genitive case for slavic languages. (localized: "january", 
//           "ledna", "januar", "stycznia", "января", "janvier", "enero", "gennaio")
//     %3 — day
//     %4 — hour
//    %44 — hour as AM/PM (ante/post meridiem)
//    %54 — ante/post meridiem abbr
//     %5 — minute
//     %6 — second
//     %7 — millisecond
//
// Examples:
//
//    [[1967, 4, 12, 16, 10, 20, 30], "%1/%2/%3 %44:%5:%6 %54"] invoke(FormatDate)
//    // returns: "1967/04/12 04:10:20 PM"
//    
//    [[1967, 4, 13, 11, 32, 11, 32], "%1/%2/%3 %44:%5:%6 %54"] invoke(FormatDate)
//    // returns: "1967/04/13 11:32:11 AM"
//    
//    [invoke(GetDate), "%3 %12 %1"] invoke(FormatDate)
//    // returns: "12 April 1967"
//

func(FormatDate) = {

    private ["_time", "_format", "_sxd", "_dec", "_month", "_hour"];

    _time = arg(0);
    _format = argOr(1,"%3 %12 %1");

    _sxd = { floor _this % 60 };
    _dec = { format ["%1%2", floor(_this / 10), _this % 10] };

    _time = (switch (typeName _time) do {
        case "ARRAY" : {
            _time
        };
        case "SCALAR" : {
            [
                0, 0, 0,
                _time call _sxd,
                60 * _time call _sxd,
                3600 * _time call _sxd,
                216000 * _time call _sxd
            ]
        };
        default { nil };
    });

    if (isNil "_time") exitwith { _format };

    _hour = _time select 3;
    _month = _time select 1;

    for "_i" from 1 to count _time - 1 do {
        _time set [_i, (_time select _i) call _dec];
    };

    if (_month > 0 && _month <= 12) then {
        _time set [11, localize ("STR/CSS/TimeFormat/" + str _month)];
        _time set [21, localize ("STR/CSS/TimeFormat/Genitive/" + str _month)];
    };

    _time set [43, (floor ((_hour + 23) % 12) + 1) call _dec];
    _time set [53,
        [
            localize "STR/CSS/TimeFormat/AM",
            localize "STR/CSS/TimeFormat/PM"
        ] select (floor(_hour) >= 12)
    ];

    format ([_format] + _time + _time);
};
