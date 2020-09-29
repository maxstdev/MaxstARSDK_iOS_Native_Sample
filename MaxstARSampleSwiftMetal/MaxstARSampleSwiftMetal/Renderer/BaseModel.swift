//
//  BaseModel.swift
//  MaxstARSampleSwiftMetal
//
//  Created by Kimseunglee on 2018. 1. 23..
//  Copyright © 2018년 Maxst. All rights reserved.
//

import UIKit
import simd
import MaxstARSDKFramework

class BaseModel: NSObject {
    var device: MTLDevice?
    var rps: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    
    var projectionMatrix:matrix_float4x4!  = matrix_identity_float4x4
    var modelMatrix:matrix_float4x4! = matrix_identity_float4x4
    var localMVPMatrix:matrix_float4x4! = matrix_identity_float4x4
    
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
}
