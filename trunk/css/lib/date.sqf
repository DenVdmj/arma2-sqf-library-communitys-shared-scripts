// SQF
//
// sqf-library "\css\lib\date.sqf"
// Copyright (c) 2009-2010 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"

func(GetDate) = {
    date call {
        _this set [4, floor( 60 * dayTime % 60 )];
        _this set [5, floor( 3600 * dayTime % 60 )];
        _this set [6, floor( 216000 * dayTime % 60 )];
        _this;
    };
};

func(SetDate) = {
    +_this call {
        _this resize 5;
        setDate _this;
    };
    skipTime ((_this select 5) / 3600);
    skipTime ((_this select 6) / 216000);
};

/*
    format string:
        %1 - year
        %2 - month number
       %12 - month string
       %22 - month string
        %3 - day
        %4 - hour
       %44 - hour as AM/PM (ante/post meridiem)
       %54 - ante/post meridiem abbr
        %5 - minute
        %6 - second
        %7 - millisecond
*/

func(FormatDate) = {

    private ["_time", "_format", "_sxd", "_dec", "_month", "_hour"];

    _time = arg(0);
    _format = arg(1);

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
        _time set [11, localize ("STR:CSS:FormatTime:" + str _month)];
        _time set [21, localize ("STR:CSS:FormatTime:genitive:" + str _month)];
    };

    _time set [43, (floor ((_hour + 23) % 12) + 1) call _dec];
    _time set [53,
        [
            localize "STR:CSS:FormatTime:AM",
            localize "STR:CSS:FormatTime:PM"
        ] select (floor(_hour) >= 12)
    ];

    format ([_format] + _time + _time);
};
