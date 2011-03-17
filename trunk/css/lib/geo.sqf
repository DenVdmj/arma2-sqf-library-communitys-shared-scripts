// SQF
//
// sqf-library "\css\lib\geo.sqf"
// Copyright (c) 2009-2010 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"

func(ViewportVector) = {
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

func(Vector2Azimuth) = {
    private ["_x", "_y"];
    _x = x(_this);
    _y = y(_this);
    if (_x == 0 && _y == 0) then { -36e7 } else { ( 360 + (_x atan2 _y) ) % 360 }
};

func(Azimuth) = {
    private ["_a", "_b"];
    _a = arg(0);
    _b = arg(1);
    [
        x(_b) - x(_a),
        y(_b) - y(_a)
    ] invoke(Vector2Azimuth)
};

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
        // "Аэропорты", список config указателей, содержащих свойства ilsPosition, ilsDirection, ilsTaxiIn, ilsTaxiOff, drawTaxiway
        [_confWorld] + (
            [_confWorld >> "SecondaryAirports", {
                if (isClass _x) then { _x }
            }] invoke(MapGrep)
        )
    );
    _nearest
};

