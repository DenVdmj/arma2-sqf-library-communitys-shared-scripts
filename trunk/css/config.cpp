
class CfgPatches {
    class css_lib {
        units[] = {};
        weapons[] = {};
        requiredVersion = 0.1;
        requiredAddons[] = {};
    };
};

class CfgMods {
    class css {
        dir = "@\CSS";
        name = "Community`s shared scripts";
        picture = "";
        hidePicture = "true";
        hideName = "true";
        actionName = "Website";
        action = "";
    };
};

class CfgVehicles {
    class Logic;
    class css_lib : Logic {
        displayName = "$STR/CSS/DISPLAY_NAME";
        icon = "\css\files\ico\icon.paa";
        picture = "\css\files\ico\icon.paa";
        vehicleClass = "Modules";
        class EventHandlers {
            init = "call compile preprocessFileLineNumbers '\css\init.sqf'";
        };
    };
};
