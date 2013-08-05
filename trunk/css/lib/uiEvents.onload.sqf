
#include "\css\css"
#include "uiEvents.macro"

(call {
    private ["_dspl", "_arr", "_idd"];

    _dspl = arg(0);
    _arr = toArray str _dspl;

    for "_i" from 0 to 8 do {
        _arr set [_i, 0x30]
    };

    _idd = parseNumber toString _arr;

    {
        _dspl displayAddEventHandler [_x, format ['[%1, "%2", _this] call (missionNamespace getVariable __funcCommonEH)', _idd, _x]];
    } foreach (__supportedEHTypes - ["load"]);

    if (isNil __ehID(_idd)) then {
        missionNamespace setVariable [__ehID(_idd), 0];
    };

    if (isNil __funcCommonEH) then {
        missionNamespace setVariable [__funcCommonEH, {
            try {
                {
                    ((+arg(2)) call _x) call {
                        if (typeName _this == typeName true) then {
                            if (_this) then {
                                throw true
                            }
                        }
                    }
                } foreach (missionNamespace getVariable __ehList(arg(0),arg(1)));
                false
            } catch {
                _exception
            }
        }];
    };

    [_idd, "load", _this]

}) call {
    _this call (missionNamespace getVariable __funcCommonEH);
};
