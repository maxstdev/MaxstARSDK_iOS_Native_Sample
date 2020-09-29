//
//  String+Extension.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 12..
//  Copyright © 2017년 Maxst. All rights reserved.
//
import UIKit

extension String {
    
    var lastPathComponent: String {
        
        get {
            return (self as NSString).lastPathComponent
        }
    }
    var pathExtension: String {
        
        get {
            return (self as NSString).pathExtension
        }
    }
    var deletingLastPathComponent: String {

        get {
            return (self as NSString).deletingLastPathComponent
        }
    }
    var deletingPathExtension: String {
        
        get {
            return (self as NSString).deletingPathExtension
        }
    }
    var pathComponents: [String] {
        
        get {
            return (self as NSString).pathComponents
        }
    }
    
    func appendingPathComponent(path: String) -> String {
        
        let nsSt = self as NSString
        
        return nsSt.appendingPathComponent(path)
    }
    
    func appendingPathExtension(ext: String) -> String? {
        
        let nsSt = self as NSString
        
        return nsSt.appendingPathExtension(ext)
    }
}
