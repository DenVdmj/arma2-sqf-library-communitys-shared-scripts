// SQF
//
// sqf-library "\css\lib\uiEvents.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

#include "uiEvents.macro"

//
// Function func(MissionDisplayAddEventHandler)
// Syntax:
//     [number IDD, string EventType, code EventHandler] invoke(MissionDisplayAddEventHandler)
//  Add display event handler on 46, 54, 106 display.
//  You can add event handlers on inactive display.
//  For example, we add "onload" event handler on RscDisplayGear
//  display, for interrupt of opening inventory:
//
//      _ehID = [106, "load", {hint str _this}] invoke(MissionDisplayAddEventHandler)
//
//

func(MissionDisplayAddEventHandler) = {
    private ["_idd", "_ehType", "_ehCode", "_ehList", "_idList", "_ehID"];
    _idd = arg(0);
    if !(_idd in __supportedDisplays) exitWith { -1 };

    _ehType = toLower arg(1);
    if !(_ehType in __supportedEHTypes) exitWith { -1 };

    _ehCode = arg(2);
    if (typeName _ehCode != typeName {}) exitWith { -1 };

    _ehList = missionNamespace getVariable [__ehList(_idd,_ehType), []];
    _idList = missionNamespace getVariable [__idList(_idd,_ehType), []];

    _ehID = 1 + (missionNamespace getVariable [__ehID(_idd), 0]);
    missionNamespace setVariable [__ehID(_idd), _ehID];

    __push(_ehList, _ehCode);
    __push(_idList, _ehID);

    missionNamespace setVariable [__ehList(_idd,_ehType), _ehList];
    missionNamespace setVariable [__idList(_idd,_ehType), _idList];

    _ehID;
};

//
// Function func(MissionDisplayAddEventHandler)
// Syntax:
//     [number IDD, string EventType, number EventHandlerID] invoke(MissionDisplayRemoveEventHandler)
//  Remove display event handler
//  Example:
//      [106, "load", _ehID] invoke(MissionDisplayRemoveEventHandler)
//

func(MissionDisplayRemoveEventHandler) = {

    private ["_idd", "_ehType", "_ehID", "_ehList"];

    _idd = arg(0);
    if !(_idd in __supportedDisplays) exitWith { false };

    _ehType = toLower arg(1);
    if !(_ehType in __supportedEHTypes) exitWith { false };

    _ehID = arg(2);

    if (typeName _ehID != typeName 0) exitWith { false };
    if (_ehID < 1) exitWith { false };

    _ehList = missionNamespace getVariable __ehList(_idd,_ehType);
    _idList = missionNamespace getVariable __idList(_idd,_ehType);

    _index = _idList find _ehID;
    if (_index < 0) exitwith { false };

    _ehList set [_index, ""];
    _idList set [_index, ""];

    _ehList = _ehList - [""];
    _idList = _idList - [""];

    missionNamespace setVariable [__ehList(_idd,_ehType), _ehList];
    missionNamespace setVariable [__idList(_idd,_ehType), _idList];

    true;
};

"ok"
