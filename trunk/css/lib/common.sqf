// SQF
//
// sqf-library "\css\lib\common.sqf"
// Copyright (c) 2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

//
// Function func(AddAction)
// Syntax:
//     _actionID = [
//         object, title, function
//         (, arguments, priority, showWindow, hideOnUse, shortcut, condition)
//     ] invoke(AddAction)
//
// Description:
//     Function func(AddAction), it is wrapper over addAction for sqf-function directly usage.
//
// Parameters:
//     0) Object object             — The object which the action is assigned to
//     1) String (or Text) title    — The action name which is displayed in the action menu.
//     2) Code (or String) function — sqf-function (or sqf-file) that is called when the action is activated.
//        Parameters of the called script upon activation:
//          [target, caller, actionID (, arguments)]
//              0) Object target      — the object which the action is assigned to
//              1) Object caller      — the unit that activated the action
//              2) Number actionID    — ID of the activated action
//              3) Anything arguments — arguments given to the script if you are using the extended syntax
// Optional parameters:
//     3) Anything arguments  — Arguments to pass to the script (will be (_this select 3) for the script)
//     4) Number   priority   — Priority value of the action. Actions will be arranged descending according
//        to this. Every game action has a preset priority value. Value can be negative or decimal.
//        Actions with same values will be arranged in order which they were made, newest at the bottom.
//        Typical range is 0 (low priority. Eg: 'Get out') to 6 (high priority. Eg: 'Auto-hover on').
//     5) Boolean  showWindow — If set True; players see "Titletext". At mid-lower screen, as they
//        approach the object. False turns it off.
//     6) Boolean  hideOnUse  — If set to true, it will hide the action menu after selecting that action.
//        If set to false, it will leave the action menu open and visible after selecting that action,
//        leaving the same action highlighted, for the purpose of allowing you to reselect that
//        same action quickly, or to select another action.
//     7) String   shortcut   — One of the key names defined in bin.pbo (e.g. "moveForward"). Default: ""
//     8) String   condition  — Code that must return true for action to be shown.
//        Special variables "_target" (unit to which action is attached to) and "_this" (caller/executing unit)
//        can be used in the evaluation. Default: true
//
// Return value:
//     Number or Nothing.
//     The ID of the action is returned, IDs are incrementing. The first given action to each unit has got
//     the ID 0, the second the ID 1 etc. ID's are also passed to the called script and used
//     to remove an action with removeAction.
//
// Snippet:
//     _actionID = [
//         _unit, localize "str/module name/action name", {
//            // action handler
//             _target    = arg(0);
//             _caller    = arg(1);
//             _actionID  = arg(2);
//             _arguments = arg(3);
//         }
//         //, arguments
//         //, priority
//         //, showWindow
//         //, hideOnUse
//         //, shortcut
//         //, condition
//     ] invoke(AddAction);
//

func(AddAction) = {
    private ["_lOperand", "_rOperand", "_function"];
    _lOperand = _this select 0;
    _rOperand = [];
    // copy parameters from _this to _rOperand
    for "_i" from 1 to count _this-1 do {
        _rOperand set [count _rOperand, _this select _i]
    };
    _function = _rOperand select 1;
    if (typeName _function != "CODE") then {
        _function = compile preprocessFileLineNumbers _function;
    };
    // change <arguments> parameter [function, arguments]
    _rOperand set [2, [_function, _rOperand select 2]];
    // change <filename> parameter
    _rOperand set [1, '__PATH__\action.sqs'];
    // add action
    _lOperand addAction _rOperand;
};

//
// Function func(CallOnOneTick)
// Syntax:
//     _result = [_sqfFunction, _arguments] invoke(CallOnOneTick)
// Description:
//     Executes given sqf-code in non scheduling environment.
//

func(CallOnOneTick) = {
    _this = [_this, nil, false];
    _this exec '__PATH__\executor.sqs';
    waitUntil {_this select 2};
    _this select 1;
};

//
// Function func(GetAspectRatio)
// Syntax:
//     invoke(GetAspectRatio)
// Description:
//     Get current aspect ratio (coefficient).
//     For example: 16/9 == 1.(7), 1280/960 or 4/3 == 1.(3)
//

func(GetAspectRatio) = (
    if (count supportInfo "*:getResolution" != 0) then {{
        getResolution select 4
    }} else {{
        (safeZoneW * 4) /
        (safeZoneH * 3)
    }}
);

//
// Function func(NumToRadix)
// Syntax:
//      [number (, radix (, minwidth (, maxwidth))))] invoke(NumToRadix)
//

func(NumToRadix) = {
    private ['_base36chars', '_number', '_radix', '_minwidth', '_maxwidth', '_string'];
    _base36chars = toArray '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    _number = arg(0);
    _radix = argOr(1,16);
    assert (_radix >= 2 && _radix <= 36);
    if (_radix < 2 || _radix > 36) exitwith { "illegal radix" };
    _minwidth = argOr(2,1);
    _maxwidth = argOr(3,__mathInf);
    _string = '';
    for "" from 1 to 10000 do {
        if (_maxwidth <= 0) exitwith {};
        if (_number <= 0 && _minwidth <= 0) exitwith {};
        _string = toString [_base36chars select (_number % _radix)] + _string;
        _number = floor (_number/_radix);
        _(minwidth)-1;
        _(maxwidth)-1;
    };
    _string
};

//
// Function func(RGB2HTMLColor)
// Syntax:
//      [number red, number green, number blue] invoke(RGB2HTMLColor)
// Returns html-style color string
//

func(RGB2HTMLColor) = {
    "#" +
    ([
        (((round arg(0)) min 0xff) max 0) * 0x10000 +
        (((round arg(1)) min 0xff) max 0) * 0x100 +
        (((round arg(2)) min 0xff) max 0),
        16, 6, 6
    ] invoke(NumToRadix))
};
