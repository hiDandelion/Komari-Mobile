//
//  DeviceCensorship.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation
import UIKit

public enum DeviceCensorship {
    public static func isChinaDevice() -> Bool {
        let bannedCharacter = "\u{1F1F9}\u{1F1FC}" as NSString
        let attributes = [NSAttributedString.Key.font:
                            UIFont.systemFont(ofSize: 8)]
        UIGraphicsBeginImageContext(bannedCharacter.size(withAttributes: attributes))
        bannedCharacter.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
        var imagePNG: Data?
        if let charImage = UIGraphicsGetImageFromCurrentImageContext() {
            imagePNG = charImage.pngData()
        }
        UIGraphicsEndImageContext()
        guard let imagePNG else {
            return false
        }
        guard let uiImage = UIImage(data: imagePNG) else {
            return false
        }
        guard let cgImage = uiImage.cgImage else { return false }
        guard let cgImageData = cgImage.dataProvider?.data as Data? else { return false }
        let imageData = cgImageData
        let rawData: UnsafePointer<UInt8> = CFDataGetBytePtr(imageData as CFData)
        for index in stride(from: 0, to: imageData.count, by: 4) {
            let r = rawData[index]
            let g = rawData[index + 1]
            let b = rawData[index + 2]
            if !(r == g && g == b) {
                return false
            }
        }
        return true
    }
}
