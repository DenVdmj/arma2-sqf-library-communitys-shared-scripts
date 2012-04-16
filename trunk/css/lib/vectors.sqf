// SQF
//
// sqf-library "\css\lib\vectors.sqf"
// Copyright (c) 2009-2012 Denis Usenko (DenVdmj)
// MIT-style license
//

#include "\css\css"
#define __PATH__ \css\lib

//
// Function func(VectorAdd)
// Syntax:
//     [vector v1, vector v2] invoke(VectorAdd)
//
// Returns the sum of the vectors v1 and v2.
// Note: vector type—is a vector3D, array of three number.
// Return value: Vector
//

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

//
// Function func(VectorSubstract)
// Syntax:
//     [vector v1, vector v2] invoke(VectorSubstract)
//
// Subtracts two vectors (v1-v2) and returns the difference.
// Note: vector type—is a 3D vector, array of three number.
// Return value: vector
// 

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

//
// Function func(VectorMagnitude)
// Syntax:
//     (vector v) invoke(VectorMagnitude)
//
// Returns the magnitude (vector length) of a given 3D vector.
// Return value: scalar
//

func(VectorMagnitude) = {
    _this distance [0, 0, 0]
};

//
// Function func(VectorNormalize)
// Syntax:
//     [] invoke(VectorNormalize)
//
// Returns the normalized version of a vector (each entry of the vector 
// divided by its magnitude). A normalized vector has a magnitude of 1.
// Return value: vector
//

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

//
// Function func(VectorTo)
// Syntax:
//     [vector v, vector p] invoke(VectorTo)
//
// Returns the vector v from this point to the given point p.
// Return value: vector
//

func(VectorTo) = {
    [arg(1), arg(0)] invoke(VectorSubstract)
};

//
// Function func(VectorProduct)
// Syntax:
//     [vector v1, vector v2] invoke(VectorProduct)
//     [scalar s, vector v] invoke(VectorProduct)
//
// Returns vector product of two vectors.
// Return value: vector
//

func(VectorProduct) = {
    private ["_v", "_u"];
    _v = arg(0);
    _u = arg(1);
    if (__isArray(_u)) then {
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

//
// Function func(VectorScalarProduct)
// Syntax:
//     [vector v1, vector v2] invoke(VectorScalarProduct)
//
// Returns the vector resulting from scalar multiplication.
// Return value: scalar
//

func(VectorScalarProduct) = {
    private ["_v", "_u"];
    _v = arg(0);
    _u = arg(1);
    x(_v) * x(_u) + y(_v) * y(_u) + z(_v) * z(_u)
};

//
// Function func(VectorAngle)
// Syntax:
//     (vector v) invoke(VectorAngle)
//     [vector v1, vector v2] invoke(VectorAngle)
// 
// When one argument: returns angle between Ox axis and vector direction, in Counter 
// clockwise orientation. The result is normalised between 0 and 2*PI.
// When two arguments: Returns the angle from vector V1 to vector V2, 
// in counter-clockwise order, and in degrees.
//
// Return value: scalar, angle in degrees
//

func(VectorAngle) = {
    private ["_v", "_u"];
    _v = arg(0);
    _u = argIfExist(1) else { [x(_v), y(_v), 0] };
    acos(([_v, _u] invoke(VectorScalarProduct)) / (_v invoke(VectorMagnitude) * _u invoke(VectorMagnitude)))
};

//
// Function func(VectorSide)
// Syntax:
//     [number vectorDir, number vectorUp] invoke(VectorSide)
//     (object vehicle) invoke(VectorSide)
// When two arguments: calculates vector side from given vectorDir and vectorUp and returns it.
// When one argument: calculates vector side of object and returns it.
// Return value: vector
//

func(VectorSide) = {
    (
        ( 
            if (__isObject(arg(0))) then {
                [vectorDir _this, vectorUp _this]
            } else {
                _this 
            }
        ) invoke(VectorProduct)
    ) invoke(VectorNormalize)
};

/*
func(VectorSide) = {
    if (__isObject(arg(0))) then {
        (
            [vectorDir _this, vectorUp _this] invoke(VectorProduct)
        ) invoke(VectorNormalize)
    } else {
        (
            [arg(0), arg(1)] invoke(VectorProduct)
        ) invoke(VectorNormalize)    
    }
};
*/
