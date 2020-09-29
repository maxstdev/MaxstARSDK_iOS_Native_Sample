//
//  MaxstUtil.swift
//  MaxstARSampleSwiftMetal
//
//  Created by keane on 28/01/2019.
//  Copyright © 2019 Maxst. All rights reserved.
//

import Foundation
import UIKit

extension Float {
    func compareDemicalPoint(_ compareValue:Float, _ point:Int) -> Bool {
        var value = self - compareValue
        value = value * (Float(pow(10.0, Double(point))))
        
        
        if(!(value <= 1 && value >= -1)) {
            return false
        }
        return true
    }
}

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    static func convertGrayScaleToUIImage(data:UnsafeRawPointer, width:Int, height:Int) -> UIImage? {
        let bufferLength = width*height
        
        let provider:CGDataProvider? = CGDataProvider(data: NSData(bytes: data, length: bufferLength))
        
        guard let provider_guard = provider else {
            return nil
        }
        let bitsPerComponent = 8;
        let bitsPerPixel = 8;
        let bytesPerRow = width;
        
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceGray()
        
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).union(.byteOrderMask)
        
        let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider_guard,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        
        return UIImage(cgImage: cgim!)
    }
}

