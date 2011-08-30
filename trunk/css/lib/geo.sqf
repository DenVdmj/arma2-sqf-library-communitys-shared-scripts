// SQF
//
// sqf-library "\css\lib\geo.sqf"
// Copyright (c) 2009-2010 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"


//
//  func(CurrentCameraVector)
//  syntax:
//      invoke(ViewportVector)
//  Returns the direction vector of the current camera.
//

func(CurrentCameraVector) = {
    // Author of this way -- Spooner (http://www.ofpec.com/forum/index.php?topic=31686.0)
    private ["_viewport", "_target"];
    _viewport = positionCameraToWorld [0, 0, 0];
    _target = positionCameraToWorld [0, 0, 1e+10];
    [
        (x(_target) - x(_viewport)) * 1e-10,
        (y(_target) - y(_viewport)) * 1e-10,
        (z(_target) - z(_viewport)) * 1e-10
    ]
};


//
//  func(CurrentCameraPosition)
//  syntax:
//      func(ViewportPosition)
//  Returns the position of the current camera.
//

func(CurrentCameraPosition) = {
    positionCameraToWorld [0, 0, 0];
};


//
//  func(GetFOV)
//  syntax:
//      func(GetFOV)
//  Returns the FOV of the current camera.
//

func(GetFOV) = {
    SafeZoneW * 0.66699 / ((worldToScreen positionCameraToWorld [0, .5, .5]) distance [.5, .5]);
};


//
//  func(Vector2Azimuth)
//  syntax:
//      (Position unitVector) invoke(Vector2Azimuth)
//
//  Returns the angle (Number) in the center of the coordinate system between the Y axis and the point unitVector.
//  If the angle is impossible (zero vector) - returns a negative value.
//  Example: player weaponDirection currentWeapon player invoke(Vector2Azimuth)
//

func(Vector2Azimuth) = {
    private ["_x", "_y"];
    _x = x(_this);
    _y = y(_this);
    if (_x == 0 && _y == 0) then { -36e7 } else { ( 360 + (_x atan2 _y) ) % 360 }
};


//
//  func(Azimuth)
//  syntax:
//      [Position A, Position B] invoke(Azimuth)
//  Returns the azimuth (Number 0 .. 360), the angle at point A between the direction to the north and the direction to point B,
//  If the angle is impossible (same position) - returns a negative value.
//

func(Azimuth) = {
    private ["_a", "_b"];
    _a = arg(0);
    _b = arg(1);
    [
        x(_b) - x(_a),
        y(_b) - y(_a)
    ] invoke(Vector2Azimuth)
};

//
// func(CompassPoint)
// Syntax:
//    [
//        (Number or Vector or two Positions) direction,
//        (Number) limit,
//        (String) format,
//        (String) localization_1,
//        (String) localization_2,
//        ...
//        (String) localization_n
//    ] invoke(CompassPoint)
// Arguments:
//
//    direction    Ч Source angle (Number) or a direction vector (Vector Array) or an two items array: [from_position, to_position]
//    limit        Ч The number of compass points (4, 8, 16, 32). Default: 16.
//    format       Ч Format string, where:
//                     %1 Ч Abbreviation of the compass points (the Dutch term (old international term)):
//                             N, NtO, NNO, NOtN, NO, NOtO, ONO, OtN,
//                             O, OtS, OSO, SOtO, SO, SOtS, SSO, StO,
//                             S, StW, SSW, SWtS, SW, SWtW, WSW, WtS,
//                             W, WtN, WNW, NWtW, NW, NWtN, NNW, NtW
//
//                     %2 Ч number of points (1 .. 32)
//                     %3 Ч heading: 0 .. 359
//                     %4 Ч relative heading:
//                             0  .. 90 (N -> O, S -> W)
//                             90 ..  0 (O -> S, W -> N)
//                     %5 .. %19 Ч reserved
//                     %20 and more Ч localize strings (require the <localization> argument(s)), optional argument,
//                                     if isn't present, then by default uses a localizing string "%1"
//
//    localization  Ч Template of the localization string, such as "STR_COMPASS_POINT_%1_SHORTNAME",
//                    where %1 Ч acronym of a compass point.
//                    Within the templates are all of the above wildcards: %1 %2 %3 %4
//
// The function returns a format string filled with actual data.
// Example:
//
//    hint ( [ getdir player, 16 ] invoke(CompassPoint) )
//
// Example:
//
//    hint (
//        [
//            [getpos player, getpos SomeObject],
//            32,
//            "Rumb: %1\nRumb Num: %2\nFull degree: %3\nQuarter degree: %4\nL1: %20\nL2: %21\nL3: %22",
//            "STR:RHUMB:%1:FN",
//            "STR:RHUMB:DUTCH:%1:SN",
//            "STR:RHUMB:EN:%1:SN"
//        ] invoke(CompassPoint)
//    )
//

func(CompassPoint) = {
    // Author of original idea -- Spooner
    private ["_degree", "_rumbsLimit", "_format", "_out", "_qDegree", "_rumbNum", "_rumb"];
    _degree = round (
        arg(0) call {
            if (IS_ARR(_this)) then {
                _this call ( if (IS_ARR(arg(0))) then { func(Azimuth) } else { func(Vector2Azimuth) } )
            } else { _this }
        }
    );
    _rumbsLimit = argOr(1,16);
    _format = argOr(2,"%1");
    _qDegree = round(_degree % 90) call { if (floor(_degree / 90) % 2 == 0) then { _this } else { 90 - _this } };
    _rumbNum = (round(.00277777777777778 * _degree * _rumbsLimit) * (32 / _rumbsLimit)) % 32;
    _rumb = [
        "N", "NtO", "NNO", "NOtN", "NO", "NOtO", "ONO", "OtN",
        "O", "OtS", "OSO", "SOtO", "SO", "SOtS", "SSO", "StO",
        "S", "StW", "SSW", "SWtS", "SW", "SWtW", "WSW", "WtS",
        "W", "WtN", "WNW", "NWtW", "NW", "NWtN", "NNW", "NtW"
    ] select _rumbNum;
    _out = [_format, _rumb, 1 + round(.08888888888888889 * _degree) % 32, _degree, _qDegree];
    for "_i" from 3 to count _this - 1 do {
        _out set [17 + _i, localize format [arg(_i), _rumb]]
    };
    format _out
};

func(GetNearestTown) = {
    [_this, ["NameCityCapital", "NameVillage", "NameCity"]] invoke(GetNearestTopography)
};

func(GetNearestLocal) = {
    [_this, ["NameCityCapital", "NameVillage", "NameCity", "NameLocal"]] invoke(GetNearestTopography)
};

func(GetNearestForest) = {
    [_this, ["VegetationFir", "VegetationBroadleaf", "VegetationVineyard", "VegetationPalm"]] invoke(GetNearestTopography)
};

func(GetNearestTopography) = {

    private [
        "_cfgRegion",
        "_cfgRegions",
        "_distance",
        "_minDistance",
        "_nearestRegion",
        "_position",
        "_requiredTypes",
        "_regionType"
    ];

    _position = arg(0);
    _requestedTypes = arg(1) call {
        if (IS_ARR(_this)) then { _this } else { [_this] }
    };

    _cfgRegions = configFile >> "CfgWorlds" >> worldName >> "Names";
    _minDistance = 1e+99; // 1.#INF
    _nearestRegion = configFile >> ";-)";

    for "_i" from 0 to count _cfgRegions - 1 do {
        _cfgRegion = _cfgRegions select _i;
        _regionType = getText (_cfgRegion >> "type");
        // caseignored "in": if (_regionType in _requestedTypes) then { ... }
        { if (_x == _regionType) exitwith { if true }; if false } foreach _requestedTypes then {
            _distance = getArray (_cfgRegion >> "position") distance _position;
            if (_distance < _minDistance) then {
                _minDistance = _distance;
                _nearestRegion = _cfgRegion
            };
        };
    };
    _nearestRegion
};

func(NearAirport) = {
    private ["_position", "_confWorld", "_minDistance", "_distance", "_nearest"];
    _position = _this;
    _confWorld = configFile >> "CfgWorlds" >> worldName;
    _minDistance = 1e+99; // 1.#INF
    {
        _distance = getArray (_x >> "ilsPosition") distance _position;
        if (_distance < _minDistance) then {
            _minDistance = _distance;
            _nearest = _x;
        };
    } foreach (
        // "јэропорты", список config указателей, содержащих свойства ilsPosition, ilsDirection, ilsTaxiIn, ilsTaxiOff, drawTaxiway
        [_confWorld] + (
            [_confWorld >> "SecondaryAirports", {
                if (isClass _x) then { _x }
            }] invoke(MapGrep)
        )
    );
    _nearest
};

