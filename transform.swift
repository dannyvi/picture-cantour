//
//  genmaps.swift
//  PicAnalyze
//
//  Created by DannyV on 16/3/30.
//  Copyright © 2016年 YuDan. All rights reserved.
//

import Foundation
import simd

//struct IMIndex {
//        var index1: uint3!
//        var index2: uint3!
    
//};

func Identity() -> float4x4
{
    //let X = float4(1 , 0 , 0 , 0)
    //let Y = float4(0 , 1 , 0 , 0)
    //let Z = float4(0 , 1 , 1 , 0)
    //let W = float4(0 , 0 , 0 , 1)
    
    let mat = float4x4(diagonal: float4(1,1,1,1))

    return mat
}

/*func OrthogonalProjection(aspect: Float, near : Float, far : Float) -> float4x4
{
    //let xScale = 1 / (far - near)
    //let yScale = xScale / aspect
    let P = float4(1.6, 0,          0,  0)
    let Q = float4(0, 1.6 * aspect, 0,  0)
    let R = float4(0, 0,          1 / (far - near) , -near / (far - near))
    let S = float4(0, 0,          0,  1)
    
    return float4x4([P,Q,R,S])
}*/


func Scale(x: Float, y: Float, z: Float) -> float4x4
{
    let s:float4 = float4(x,y,z,1.0)
    return float4x4(diagonal: s)
}

func Scale(xyz: float3) -> float4x4
{
    let v = float4(xyz.x,xyz.y,xyz.z,1.0)
    return float4x4(diagonal: v)
}

func Translate(x:Float, y: Float, z:Float) -> float4x4
{
    var M = Identity()
    M[3].x = x
    M[3].y = y
    M[3].z = z
    return M
}

func Translate(xyz:float3) -> float4x4
{
    var M = Identity()
    M[3].x = xyz.x
    M[3].y = xyz.y
    M[3].z = xyz.z
    return M
}

func DegToRad(deg:Float) ->Float
{
    return deg * Float(M_PI / 180.0)
}


func RotationL(axis:float3, angle: Float) -> float4x4
{
    let a = DegToRad(angle)
    let c = cos(a)
    let s = sin(a)
    
    let k = 1.0 - c
    
    let u = normalize(axis)
    let v = s * u
    let w = k * u
    
    var P = float4(0.0)
    var Q = float4(0.0)
    var R = float4(0.0)
    var S = float4(0.0)
    
    P.x = w.x * u.x + c
    P.y = w.x * u.y + v.z
    P.z = w.x * u.z - v.y
    
    Q.x = w.x * u.y - v.z
    Q.y = w.y * u.y + c
    Q.z = w.y * u.z + v.x
    
    R.x = w.x * u.z + v.y
    R.y = w.y * u.z - v.x
    R.z = w.z * u.z + c
    
    S.w = 1.0
    
    let mat = float4x4([P,Q,R,S])
    return mat
}


func PerspectiveFovL(aspect: Float, fovy: Float, near : Float, far : Float) -> float4x4
{
    let angle = DegToRad(0.5 * fovy)
    let yScale = 1 / tan(angle)
    let xScale = yScale / aspect
    let zScale = far / (far - near)   //-(far + near) / zRange
    //let wzScale = -2 * far * near / zRange
    
    let P = float4(xScale,0,0,0)
    let Q = float4(0,yScale,0,0)
    let R = float4(0,0,zScale,1.0)
    let S = float4(0,0,-near * zScale,0)
    
    let mat = float4x4([P,Q,R,S])
    return mat
}

func PerspectiveL(width:Float, height:Float, near:Float, far:Float) -> float4x4
{
    let zNear = 2.0 * near
    let zFar  = far / (far - near)
    
    var P = float4(0.0)
    var Q = float4(0.0)
    var R = float4(0.0)
    var S = float4(0.0)
    
    P.x = zNear / width
    Q.y = zNear / height
    R.z = zFar
    R.w = 1.0
    S.z = -near * zFar
    
    return float4x4([P,Q,R,S])
}

func LookAtL(eye:float3, center:float3, up:float3) -> float4x4
{
    let E = -eye
    var N = normalize(center + E)
    var U = normalize(cross(up,N))
    var V = cross(N,U)
    
    var P = float4(0.0)
    var Q = float4(0.0)
    var R = float4(0.0)
    var S = float4(0.0)
    
    P.x = U.x
    P.y = V.x
    P.z = N.x
    
    Q.x = U.y
    Q.y = V.y
    Q.z = N.y
    
    R.x = U.z
    R.y = V.z
    R.z = N.z
    
    S.x = simd.dot(U, E)
    S.y = dot(V,E)
    S.z = dot(N,E)
    S.w = 1.0
    
    return float4x4([P,Q,R,S])
}

func Ortho2DL(left left:Float,right:Float,bottom:Float, top:Float, near:Float, far:Float) -> float4x4
{
    let sWidth = 1.0  / (right - left)
    let sHeight = 1.0 / (top - bottom)
    let sDepth = 1.0  / (far  - near)
    
    var P = float4(0.0)
    var Q = float4(0.0)
    var R = float4(0.0)
    var S = float4(0.0)
    
    P.x = 2.0 * sWidth
    Q.y = 2.0 * sHeight
    R.z = sDepth

    S.z = -sDepth * near
    S.w = 1.0
    
    return float4x4([P,Q,R,S])
}

func Ortho2DL(left left:Float,right:Float,bottom:Float,top:Float) -> float4x4
{
    return Ortho2DL(left: left, right: right, bottom: bottom, top: top, near: 0.0, far: 1.0)
}


func RotationR(axis:float3, angle: Float) -> float4x4
{
    let a = DegToRad(angle)
    let c = cos(a)
    let s = sin(a)
    
    let k = 1.0 - c
    
    let u = normalize(axis)
    let v = s * u
    let w = k * u
    
    var P = float4(0.0)
    var Q = float4(0.0)
    var R = float4(0.0)
    var S = float4(0.0)
    
    P.x = w.x * u.x + c
    P.y = w.x * u.y - v.z
    P.z = w.x * u.z + v.y
    
    Q.x = w.y * u.x + v.z
    Q.y = w.y * u.y + c
    Q.z = w.y * u.z - v.x
    
    R.x = w.z * u.x - v.y
    R.y = w.z * u.y + v.x
    R.z = w.z * u.z + c
    
    S.w = 1.0
    
    let mat = float4x4([P,Q,R,S])
    return mat
}


func PerspectiveFovR(aspect: Float, fovy: Float, near : Float, far : Float) -> float4x4
{
    let angle = DegToRad(0.5 * fovy)
    let f = 1.0 / tan(angle)

    let sNear = 2.0 * near
    let sDepth = 1.0 / (near - far)
    
    var P = float4(0.0)
    var Q = float4(0.0)
    var R = float4(0.0)
    var S = float4(0.0)
    
    P.x = f / aspect
    Q.y = f
    R.z = sDepth * (far + near)
    R.w = -1.0
    S.z = sNear * sDepth * far
    
    return float4x4([P,Q,R,S])
}



func LookAtR(eye:float3, center:float3, up:float3) -> float4x4
{
    let E = -eye
    var N = normalize(eye - center)
    var U = normalize(cross(up,N))
    var V = cross(N,U)
    
    var P = float4(0.0)
    var Q = float4(0.0)
    var R = float4(0.0)
    var S = float4(0.0)
    
    P.x = U.x
    P.y = U.y  //V.x
    P.z = U.z  //N.x
    P.w = dot(U,E)
    
    Q.x = V.x  //U.y
    Q.y = V.y  //V.y
    Q.z = V.z  //N.y
    Q.w = dot(V,E)
    
    R.x = N.x  //U.z
    R.y = N.y  //V.z
    R.z = N.z  //N.z
    R.w = dot(N,E)
    
    //S.x = simd.dot(U, E)
    //S.y = dot(V,E)
    //S.z = dot(N,E)
    S.w = 1.0
    
    return float4x4([P,Q,R,S])
}

func Ortho2DR(left left:Float,right:Float,bottom:Float, top:Float, near:Float, far:Float) -> float4x4
{
    let sWidth = 1.0  / (right - left)
    let sHeight = 1.0 / (top - bottom)
    let sDepth = 1.0  / (far  - near)
    
    var P = float4(0.0)
    var Q = float4(0.0)
    var R = float4(0.0)
    var S = float4(0.0)
    
    P.x = 2.0 * sWidth
    Q.y = 2.0 * sHeight
    R.z = -2.0 * sDepth
    S.x = -sWidth * (right + left)
    S.y = -sDepth * (top + bottom)
    S.z = -sDepth * (far + near)
    //S.z = -sDepth * near
    S.w = 1.0
    
    return float4x4([P,Q,R,S])
}

func Ortho2DR(left left:Float,right:Float,bottom:Float,top:Float) -> float4x4
{
    return Ortho2DR(left: left, right: right, bottom: bottom, top: top, near: 0.0, far: 1.0)
}










