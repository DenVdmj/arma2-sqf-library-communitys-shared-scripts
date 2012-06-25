// SQF
//
// sqf-library "\css\lib\mp.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

//
// Function func(BroadcastCall)
//
// Syntax:
//     [<condition>, <argument>, <sqf function>] invoke(BroadcastCall);
//
// Arguments:
//     <condition>
//         Code or String type.
//         Condition, such as: {isDedicated}, {local _this && myFlagIsTrue}, etc.
//         Also, <condition> can be a string value:
//             'all'         — for all;
//             'isClient'    — clients only;
//             'isServer'    — server only;
//             'isDedicated' — dedicated server only.
//     <argument>
//         Argument them to pass to the function in the _this variables, any type.
//     <sqf function>
//         Code to execute
//
// Example 1:
//     [{isServer}, player, {
//         group _this createUnit [typeOf _this, getPos _this, [], 4, 'none']
//     }] invoke(BroadcastCall);
//
// Example 2:
//     ['all', player, {diag_log _this}] invoke(BroadcastCall);
//
// Example 3:
//     [{local _this}, cursorTarget, {
//         _this playAction 'ReloadMagazine'
//     }] invoke(BroadcastCall);
//


func(BroadcastCall) = {
    try {
        if (typeName arg(2) != 'CODE') then {
            throw false
        };
        _this set [0, switch (typeName arg(0)) do {
            case 'CODE' : {
                arg(0)
            };
            case 'STRING' : {
                switch toLower arg(0) do {
                    case 'all'      : {{true}};
                    case 'isclient' : {{!isDedicated}};
                    default { compile arg(0) };
                }
            };
            default {
                throw false
            };
        }];
        missionNamespace setVariable ['', _this];
        publicVariable '';
        if (call arg(0)) then {
            arg(1) call arg(2)
        };
        true
    } catch {
        false
    };
};

/* func(MPSetObjectTexture) = {}; */
/*
'' addPublicVariableEventHandler {
    arg(1) call {
        if (call arg(0)) then {
            arg(1) call arg(2)
        };
    };
};
*/
/*
't' addPublicVariableEventHandler {
    arg(1) call {
        _obj = arg(0);
        _selection = arg(1);
        _texture = arg(2);
        if (__isNumber(_texture)) then {

        };
        (_this select 0) setObjectTexture [_this select 1, _this select 2];
    };
};
*/
