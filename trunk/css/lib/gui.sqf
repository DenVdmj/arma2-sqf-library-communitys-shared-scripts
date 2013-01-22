// SQF
//
// sqf-library "\css\lib\gui.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

#define __setStorage __uiSet(CreateDialog/Storage)
#define __getStorage __uiGet(CreateDialog/Storage)

if (isNil{__getStorage}) then { [] __setStorage };

//
// Function func(CreateDialog)
// Syntax:
//   {
//       _rsc = "RscDisplay";
//
//       // list of local variables which available from the constructor, destructor and event handlers code
//       _private = ["_list", "_of", "_your", "_local", "_variables"];
//
//       // Event handlers,
//       _handlers = [
//           // you can declare them as follows:
//           "CtrlClassName", "EventName", {
//               // event handler code
//           },
//           // or as follows:
//           ["CtrlClassName", "AnotherCtrlClassName"],
//           ["EventName", "AnotherEventName"], {
//               // event handler code
//           }
//       ];
//       _constructor = {
//           // constructor code
//
//       };
//       _destructor = {
//            // destructor code
//       };
//
//   } invoke(CreateDialog);
//

func(CreateDialog) = {

    private ["_rsc", "_display", "_parent", "_private", "_handlers", "_constructor", "_destructor"];

    disableSerialization;

    // Automatic variables — default values
    _display = displayNull;
    _parent = objNull;
    _private = [];
    _handlers = [];
    _constructor = {};
    _destructor = {};

    // call user initialization code
    [] call _this;

    try {
        // type checking
        {
            if (isNil {_x select 0}) then {
                throw format ["Redefined any or undifined parameter: %1", _x select 1];
            };
            if (typeName (_x select 0) != _x select 2) then {
                throw format ["%1 parameter type mismatch, must be %2", _x select 1, typeName (_x select 2)]
            };
        } foreach [
            [_rsc, "_rsc", "STRING"],
            [_display, "_display", "DISPLAY"],
            [_private, "_private", "ARRAY"],
            [_handlers, "_handlers", "ARRAY"],
            [_constructor, "_constructor", "CODE"],
            [_destructor, "_destructor", "CODE"]
        ];

        // hidden in the namespace to not interfere with user code variables
        _this = call {
            // yes, i know that clever code sucks, but... someday i'll rewrite it all over again
            private "_thisScope";
            _thisScope = [
                "_thisScope", "_confDialog", "_idd",
                "_dsplPrivateValues", "_dsplMapClassnames", "_dsplMapCtrls", "_dsplMapConfs", "_dsplGetConfByCtrl",
                "_dsplSpawn", "_loadCode", "_saveCode", "_eventHandlerExecutor", "_ehTpl", "_destructorTpl", "_dsplDataIndex",
                "_handlersList", "_toArray", "_createDisplay", "_storage", "_ehCtrl", "_ehType", "_ehCode"
            ];
            private _thisScope;

            // try to turn the mission config, and game config
            // if it fails, the user asked the invalid resource name (_rsc)
            _confDialog = (missionConfigFile >> _rsc) call {
                if (isClass _this) then { _this } else {
                    (configFile >> _rsc) call {
                        if (isClass _this) then { _this } else {
                            throw ("invalid _rsc: " + str _rsc)
                        };
                    };
                };
            };

            _idd = getNumber(_confDialog >> "idd");

            // the idd must be valid, creating dialog must be successful, otherwise an error — user asked incorrect resource name (_rsc)
            if (_idd < 0) then {
                throw ("negative idd in resource class " + str _rsc)
            };

            _createDisplay = {
                (switch (typeName _this) do {
                    case "STRING": { configFile >> _this  };
                    case "CONFIG": { getNumber(_this >> "idd") };
                    case "SCALAR": { findDisplay _this };
                    case "DISPLAY": { _this createDisplay _rsc; nil };
                    default { createDialog _rsc; nil }
                }) call _createDisplay
            };

            if (isNull _display) then {
                _parent call _createDisplay;
                _display = findDisplay _idd;
            };

            if (isNull _display) then {
                throw ("null display")
            };

            _dsplMapClassnames = [];
            _dsplMapCtrls = [];
            _dsplMapConfs = [];

            // user-defined variable _private — declare variables private dialogue;
            // _dsplPrivateValues — keeps the values of these variables
            _dsplPrivateValues = [];
            _dsplPrivateValues resize count _private; // not initialized variables — nil

            _confDialog call {
                private ["_walk", "_idc"];
                _walk = {
                    if (isClass _this) then {
                        _idc = getNumber(_this >> "idc");
                        if (_idc > 0) then {
                            __push(_private, "_ctrl" + configName _this);          // extend the list of names of private controls
                            __push(_dsplPrivateValues, _display displayCtrl _idc); // write down their values
                            __push(_dsplMapClassnames, configName _this);
                            __push(_dsplMapCtrls, _display displayCtrl _idc);
                            __push(_dsplMapConfs, _this);
                        };
                        for "_i" from 0 to count _this - 1 do {
                            _this select _i call _walk
                        };
                    }
                };
                _this call _walk;
            };

            _dsplGetConfByCtrl = {
                _dsplMapCtrls find _this call {
                    if (_this >= 0) then {
                        _dsplMapConfs select _this
                    } else {
                        // the void config reference
                        configFile >> ";)"
                    }
                };
            };

            // find a free place (nil) in the global storage
            _storage = __getStorage; // link on global storage
            _dsplDataIndex = 0 call {
                for "_i" from 0 to count _storage do {
                    _this = _storage select _i;
                    if (isNil "_this") exitwith {_i};
                }
            };

            // export into user-code
            #define export(name) __push(_private,__q(name)); __push(_dsplPrivateValues,name);

            export(_display);
            export(_dsplMapCtrls);
            export(_dsplMapConfs);
            export(_dsplGetConfByCtrl);

            _dsplSpawn = compile format ['_this spawn { disableSerialization; __1 = __getStorage select %1; [__1 select 1, _this select 0, _this select 1] call (__1 select 0)}', _dsplDataIndex];

            export(_dsplSpawn);

            _loadCode = ""; // loader of variables
            _saveCode = ""; // unloader of variables

            for "_i" from 0 to count _private - 1 do {
                _loadCode = _loadCode + format ["%1 = __2 select %2;", _private select _i, _i];
                _saveCode = _saveCode + format ["__2 set [%2, %1];", _private select _i, _i];
            };

            // create a template of native handlers
            // %1 — _ehIndex
            _ehTpl = '__ret = false; __1 = __getStorage select %1; [__1 select 1, _this, (__1 select 2) select %2] call (__1 select 0); __ret;';
            _destructorTpl = '__1 = __getStorage select %1; [__1 select 1, _this, __1 select 3] call (__1 select 0); __getStorage set [%1, nil]';

            // create a template of common handlers
            // args: [_dsplPrivateValues, originThis, userEventHandler] call _eventHandlerExecutor

            _eventHandlerExecutor = compile (
                'private "__1"; __2 = _this select 0; ' + _loadCode +
                'call { private "__2"; (_this select 1) call (_this select 2) }; ' + _saveCode
            );

            _handlersList = [];

            _storage set [_dsplDataIndex, [_eventHandlerExecutor, _dsplPrivateValues, _handlersList, _destructor]];

            _toArray = {
                if (typeName _this == "Array") then { _this } else { [_this] }
            };

            for "_i" from 0 to count _handlers - 3 step 3 do {

                _ehCode = _handlers select _i+2;

                if (typeName _ehCode != "CODE") then {
                    throw format ["Invalid type of event handler (%1, must be CODE, index: %2)", typeName _ehCode, _i];
                };

                __push(_handlersList, _ehCode);

                {
                    _ehCtrl = _x;
                    {
                        _ehType = _x;
                        if (typeName _ehType != "STRING") then {
                            throw format ["Invalid event name (type %1, must be STRING, index: %2)", typeName _ehType, _i];
                        };
                        [_ehType, format [_ehTpl, _dsplDataIndex, count _handlersList - 1]] call {
                            switch typeName _ehCtrl do {
                                case "CODE" : {
                                    private ["_ctrl", "_conf"];
                                    for "_i" from 0 to count _dsplMapCtrls -1 do {
                                        _ctrl = _dsplMapCtrls select _i;
                                        _conf = _dsplMapConfs select _i;
                                        if (_ctrl call _ehCtrl) then {
                                            private _thisScope;
                                            _ctrl ctrlAddEventHandler _this;
                                        };
                                    };
                                };
                                case "DISPLAY" : {
                                    _display displayAddEventHandler _this;
                                };
                                case "STRING" : {
                                    switch _ehCtrl do {
                                        case _rsc : {
                                            _display displayAddEventHandler _this;
                                        };
                                        case "*" : {
                                            {
                                                _x ctrlAddEventHandler _this;
                                            } foreach _dsplMapCtrls;
                                        };
                                        default {
                                            (
                                                (_dsplMapClassnames find _ehCtrl) call { // find control's idc
                                                    if (_this < 0) then {
                                                        throw format ["One of the classes unavailable: %1 %2, index: %3", typeName _ehCtrl, _ehCtrl, _i];
                                                    } else {
                                                        _dsplMapCtrls select _this;
                                                    };
                                                }
                                            ) ctrlAddEventHandler _this;
                                        };
                                    };
                                };
                                default {
                                    throw format ["Invalid control class name or selector (type %1, must be STRING, DISPLAY or CODE, index: %2)", typeName _ehCtrl, _i];
                                };
                            };
                        };
                    } foreach (
                        (_handlers select _i+1) call _toArray
                    );
                } foreach (
                    (_handlers select _i) call _toArray
                )
            };

            _display displayAddEventHandler ["Unload",
                format [_destructorTpl, _dsplDataIndex]
            ];

            [_dsplPrivateValues, _display, _constructor, _eventHandlerExecutor, _private]
        };

        // call constructor in current namespace (constructor is called from _eventHandlerExecutor)
        _this call { private (_this select 4); call (_this select 3); };

        "OK";

    } catch {
        "Error of initialization.\n" + _exception
    };
};
