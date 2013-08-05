// ARMA 2

class RscDisplayEmpty;
class RscDisplayMission : RscDisplayEmpty {
    // idd = 46;
    onLoad = "_this call compile preprocessFileLineNumbers 'css\lib\uiEvents.onload.sqf'";
};

//class RscChatListDefault {
//    // not allowed
//    onLoad = __ONLOAD;
//};

class RscDisplayInsertMarker {
    // idd = 54;
    onLoad = "_this call compile preprocessFileLineNumbers 'css\lib\uiEvents.onload.sqf'";
};

class RscDisplayGear {
    // idd = 106;
    onLoad = "if (isNil('IGUI_GEAR_activeFilter')) then { IGUI_GEAR_activeFilter = 0 }; [_this, 'onLoad'] execVM '\ca\ui\scripts\handleGear.sqf'; _this call compile preprocessFileLineNumbers 'css\lib\uiEvents.onload.sqf'";
};

