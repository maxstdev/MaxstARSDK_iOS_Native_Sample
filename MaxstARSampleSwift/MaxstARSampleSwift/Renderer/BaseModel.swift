//
//  BaseModel.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 13..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import simd
import MaxstARSDKFramework

class BaseModel: NSObject {
    var vertices:[Float]?
    var indices:[CUnsignedChar]?
    var textureCoords:[Float]?
    var colors:[Float]?
    
    var vertexCount:Int = 0;
    var indexCount:Int = 0;
    var texCoordCount:Int = 0;
    
    var program:GLuint = 0;
    var positionHandle:GLuint = 0
    var textureCoordHandle:GLuint = 0
    var colorHandle:GLuint = 0
    var mvpMatrixHandle:GLuint = 0
    var textureCount:Int = 0
    var textureId:GLuint = 0
    var textureHandle:GLuint = 0
    
    var VertexShader:String? = nil
    var FragmentShader:String? = nil
    
    var modelMatrix:matrix_float4x4 = matrix_identity_float4x4
    var localMVPMatrix:matrix_float4x4 = matrix_identity_float4x4
    var projectionMatrix:matrix_float4x4 = matrix_identity_float4x4
    
    func draw() {
        
    }
    
    func setProjectionMatrix(projectionMatrix:matrix_float4x4) {
        self.projectionMatrix = projectionMatrix
    }
    
    func setPoseMatrix(poseMatrix:matrix_float4x4) {
        self.modelMatrix = poseMatrix
    }
    
    func setTranslation(x:Float, y:Float, z:Float) {
        let translationMatrix:matrix_float4x4 = MasMatrixUtil.translation(x, y: y, z: z)
        self.modelMatrix = matrix_multiply(self.modelMatrix, translationMatrix)
    }
    
    func setRotation(x:Float, y:Float, z:Float) {
        let rotationMatrix:matrix_float4x4 = MasMatrixUtil.rotation(x, y: y, z: z)
        self.modelMatrix = matrix_multiply(self.modelMatrix, rotationMatrix)
    }
    
    func setScale(x:Float, y:Float, z:Float) {
        let scaleMatrix:matrix_float4x4 = MasMatrixUtil.scale(x, y: y, z: z)
        self.modelMatrix = matrix_multiply(self.modelMatrix, scaleMatrix)
    }
    
    func matrixToPointer(matrix:matrix_float4x4) -> UnsafePointer<GLfloat> {
        let pointer:UnsafeMutablePointer<GLfloat> = UnsafeMutablePointer.allocate(capacity: 16)
        pointer[0] = matrix.columns.0.x
        pointer[1] = matrix.columns.0.y
        pointer[2] = matrix.columns.0.z
        pointer[3] = matrix.columns.0.w
        
        pointer[4] = matrix.columns.1.x
        pointer[5] = matrix.columns.1.y
        pointer[6] = matrix.columns.1.z
        pointer[7] = matrix.columns.1.w
        
        pointer[8] = matrix.columns.2.x
        pointer[9] = matrix.columns.2.y
        pointer[10] = matrix.columns.2.z
        pointer[11] = matrix.columns.2.w
        
        pointer[12] = matrix.columns.3.x
        pointer[13] = matrix.columns.3.y
        pointer[14] = matrix.columns.3.z
        pointer[15] = matrix.columns.3.w
        
        return UnsafePointer.init(pointer)
    }
}
