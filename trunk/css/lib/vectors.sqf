// SQF
//
// sqf-library "\css\lib\vectors.sqf"
// Copyright (c) 2009-2010 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"

func(VectorAdd) = {
    private ["_v", "_u"];
    _v = arg(0);
    _u = arg(1);
    [
        x(_v) + x(_u),
        y(_v) + y(_u),
        z(_v) + z(_u)
    ]
};

func(VectorSubstract) = {
    private ["_v", "_u"];
    _v = arg(0);
    _u = arg(1);
    [
        x(_v) - x(_u),
        y(_v) - y(_u),
        z(_v) - z(_u)
    ]
};

func(VectorMagnitude) = {
    _this distance [0, 0, 0]
};

func(VectorNormalize) = {
    private "_f";
    _f = _this invoke(VectorMagnitude);
    if (_f == 0) exitwith { [0, 0, 0] };
    _f = 1 / _f;
    [
        _f * x(_this),
        _f * y(_this),
        _f * z(_this)
    ]
};

func(VectorTo) = {
    [arg(1), arg(0)] invoke(VectorSubstract)
};

func(VectorProduct) = {
    private ["_v", "_u"];
    _v = arg(0);
    _u = arg(1);
    if (typeName _u == "array") then {
        [
            y(_v) * z(_u) - z(_v) * y(_u),
            z(_v) * x(_u) - x(_v) * z(_u),
            x(_v) * y(_u) - y(_v) * x(_u)
        ]
    } else {
        [
            _u * x(_v),
            _u * y(_v),
            _u * z(_v)
        ]
    }
};

func(VectorScalarProduct) = {
    private ["_v", "_u"];
    _v = arg(0);
    _u = arg(1);
    x(_v) * x(_u) + y(_v) * y(_u) + z(_v) * z(_u)
};

func(VectorAngle) = {
    private ["_v", "_u"];
    _v = arg(0);
    _u = argSafe(1) else { [x(_v), y(_v), 0] };
    acos(([_v, _u] invoke(VectorScalarProduct)) / (_v invoke(VectorMagnitude) * _u invoke(VectorMagnitude)))
};

func(VectorSide) = {
    (
        [vectorDir _this, vectorUp _this] invoke(VectorProduct)
    ) invoke(VectorNormalize)
};
