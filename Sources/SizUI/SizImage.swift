//
//  SizImage.swift
//  

import UIKit

// MARK: - UIImage

public extension UIImage {
    
    convenience init?(url: URL, noCache: String? = nil) {
        var imgUrl = url
        if let noCache = noCache {
            let has_q = url.absoluteString.contains("?")
            imgUrl = url.appendingPathComponent(has_q ? "&\(noCache)" : "?\(noCache)")
        }
        
        guard let data = try? Data(contentsOf: imgUrl) else { return nil }
        self.init(data: data)
    }
    
    // Image Resizing
    // https://gist.github.com/marcosgriselli/00ab6c68f48ccaeb110afc82786767ec
    
    func resized(_ targetSize: CGSize, aspectFit: Bool = true) -> UIImage {
        var newSize: CGSize
        
        if aspectFit {
            let widthRatio = targetSize.width  / size.width
            let heightRatio = targetSize.height / size.height

            if widthRatio > heightRatio {
                newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            }
            else {
                newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
            }
        }
        else {
            newSize = targetSize
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func scaled(_ scale: CGFloat) -> UIImage? {
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        return resized(scaledSize)
    }
    
}
