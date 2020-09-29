//
//  ImageUtil.swift
//  MetalTest
//
//  Created by Kimseunglee on 2017. 11. 20..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit

class ImageUtil: NSObject {
    public struct PixelData {
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8
    }
    
    static func rawImageDataToPixelData(rawData: [CUnsignedChar] , width: Int, height: Int) -> [PixelData] {
        let pixelDatas:NSMutableArray = NSMutableArray()
        
        for i in stride(from: 0, to: width * height * 4, by: 4) {
            let eachData = PixelData(r: rawData[i + 0], g: rawData[i + 1], b: rawData[i + 2], a: rawData[i + 3])
            pixelDatas.add(eachData)
        }
        
        return pixelDatas as! [ImageUtil.PixelData];
    }
    
    static func imageFromRGBA32Bitmap(pixels:[PixelData], width: Int, height: Int)-> UIImage {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).union(.byteOrder32Little)
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        
        assert(pixels.count == width * height)
        
        var data = pixels // Copy to mutable []
        let providerRef = CGDataProvider(
            data: NSData(bytes: &data, length: data.count * MemoryLayout<PixelData>.size)
        )
        
        let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * Int(MemoryLayout<PixelData>.size),
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef!,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        return UIImage(cgImage: cgim!)
    }
}
