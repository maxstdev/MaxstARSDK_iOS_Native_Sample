//
//  MathUtil.swift
//  MetalTest
//
//  Created by Kimseunglee on 2017. 9. 21..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import simd

struct Vertex {
    
    var x,y,z: Float     // position data
    var r,g,b,a: Float   // color data
    var s,t: Float       // texture coordinates
    
    func floatBuffer() -> [Float] {
        return [x,y,z,r,g,b,a,s,t]
    }
}

struct FeatureVertex {
    
    var x,y,z: Float     // position data
    var s,t: Float       // texture coordinates
    
    init(x:Float,y:Float,z:Float,s:Float,t:Float) {
        self.x = x
        self.y = y
        self.z = z
        self.s = s
        self.t = t
    }
    
    func floatBuffer() -> [Float] {
        return [x,y,z,s,t]
    }
}

struct ColorConversion {
    var matrix:matrix_float3x3
    var offset:vector_float3
}

struct Uniforms {
    var modelViewProjectionMatrix: matrix_float4x4
}

func translate(positionX: Float, positionY: Float, positionZ: Float, matrix:matrix_float4x4) -> matrix_float4x4 {
    var matrix = matrix
    let currentPosition:float4 = matrix.columns.3
    matrix.columns.3 = float4(positionX + currentPosition.x, positionY + currentPosition.y, positionZ + currentPosition.z, 1.0)
    
    return matrix;
}

func translation(x: Float, y: Float, z: Float) -> matrix_float4x4 {
    let X = vector_float4(1, 0, 0, 0)
    let Y = vector_float4(0, 1, 0, 0)
    let Z = vector_float4(0, 0, 1, 0)
    let W = vector_float4(x, y, z, 1)
    return matrix_float4x4(columns:(X, Y, Z, W))
}

func rotate(x: Float, y: Float, z: Float, matrix:matrix_float4x4) -> matrix_float4x4 {
    return matrix;
}

func scalingMatrix(scaleX: Float, scaleY: Float, scaleZ: Float) -> matrix_float4x4 {
    let X = vector_float4(scaleX, 0, 0, 0)
    let Y = vector_float4(0, scaleY, 0, 0)
    let Z = vector_float4(0, 0, scaleZ, 0)
    let W = vector_float4(0, 0, 0, 1)
    return matrix_float4x4(columns:(X, Y, Z, W))
}

func rotationMatrix(angle: Float, axis: vector_float3) -> matrix_float4x4 {
    var X = vector_float4(0, 0, 0, 0)
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * cos(angle)
    X.y = axis.x * axis.y * (1 - cos(angle)) - axis.z * sin(angle)
    X.z = axis.x * axis.z * (1 - cos(angle)) + axis.y * sin(angle)
    X.w = 0.0
    var Y = vector_float4(0, 0, 0, 0)
    Y.x = axis.x * axis.y * (1 - cos(angle)) + axis.z * sin(angle)
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * cos(angle)
    Y.z = axis.y * axis.z * (1 - cos(angle)) - axis.x * sin(angle)
    Y.w = 0.0
    var Z = vector_float4(0, 0, 0, 0)
    Z.x = axis.x * axis.z * (1 - cos(angle)) - axis.y * sin(angle)
    Z.y = axis.y * axis.z * (1 - cos(angle)) + axis.x * sin(angle)
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * cos(angle)
    Z.w = 0.0
    let W = vector_float4(0, 0, 0, 1)
    return matrix_float4x4(columns:(X, Y, Z, W))
}

func projectionMatrix(near: Float, far: Float, aspect: Float, fovy: Float) -> matrix_float4x4 {
    let scaleY = 1 / tan(fovy * 0.5)
    let scaleX = scaleY / aspect
    let scaleZ = -(far + near) / (far - near)
    let scaleW = -2 * far * near / (far - near)
    let X = vector_float4(scaleX, 0, 0, 0)
    let Y = vector_float4(0, scaleY, 0, 0)
    let Z = vector_float4(0, 0, scaleZ, -1)
    let W = vector_float4(0, 0, scaleW, 0)
    return matrix_float4x4(columns:(X, Y, Z, W))
}

func matrix_make(m00:Float, m10:Float, m20:Float, m30:Float,
                 m01:Float, m11:Float, m21:Float, m31:Float,
                 m02:Float, m12:Float, m22:Float, m32:Float,
                 m03:Float, m13:Float, m23:Float, m33:Float) -> matrix_float4x4 {
    
    return  matrix_float4x4.init(float4(m00,m01,m02,m03), float4(m10,m11,m12,m13), float4(m20,m21,m22,m23), float4(m30,m31,m32,m33))
}

func matrix_ortho(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float) -> matrix_float4x4 {
    
    let r_l = right - left;
    let t_b = top - bottom;
    let f_n = farPlane - nearPlane;
    
    let tx = -(right + left) / (right - left);
    let ty = -(top + bottom) / (top - bottom);
    let tz = -(farPlane + nearPlane) / (farPlane - nearPlane);
    
    return matrix_make(m00: 2.0 / r_l, m10: 0,         m20: 0,       m30: 0,
                       m01: 0,         m11: 2.0 / t_b, m21: 0,       m31: 0,
                       m02: 0,         m12: 0,         m22: 2.0/f_n, m32: 0,
                       m03: tx,        m13: ty,        m23: tz,      m33: 1);
}

func radiansToDegrees(radian:Float) -> Float {
    return radian * (180.0 / Float.pi)
}
func degreesToRadians(degree:Float) -> Float {
    return degree / 180.0 * Float.pi
}
