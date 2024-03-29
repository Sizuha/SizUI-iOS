//
//  SizImage.swift
//  

import UIKit
import CoreMedia

// MARK: - UIImage

public extension UIImage {
    
    static func create(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x:0, y:0, width:1.0,height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context:CGContext = UIGraphicsGetCurrentContext()!

        context.setFillColor(color.cgColor)
        context.fill(rect)

        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return image
    }
    
    convenience init?(url: URL, noCache: String? = nil) {
        var imgUrl = url
        if let noCache = noCache {
            let has_q = url.absoluteString.contains("?")
            imgUrl = url.appendingPathComponent(has_q ? "&\(noCache)" : "?\(noCache)")
        }
        
        guard let data = try? Data(contentsOf: imgUrl) else { return nil }
        self.init(data: data)
    }
    
    /// CMSampleBufferをUIImageに変換する
    convenience init?(withBuffer buffer: CMSampleBuffer) {
        // サンプルバッファからピクセルバッファを取り出す
        guard let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return nil
        }

        // ピクセルバッファをベースにCoreImageのCIImageオブジェクトを作成
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // CIImageからCGImageを作成
        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageRect:CGRect = CGRect(x: 0,y: 0, width: pixelBufferWidth, height: pixelBufferHeight)
        let ciContext = CIContext()
        guard let cgimage = ciContext.createCGImage(ciImage, from: imageRect) else {
            return nil
        }

        // CGImageからUIImageを作成
        self.init(cgImage: cgimage)
    }
    
    /// Image Resizing
    /// https://gist.github.com/marcosgriselli/00ab6c68f48ccaeb110afc82786767ec
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
    
    static let ROTATE_90: CGFloat = .pi / 2
    static let ROTATE_180: CGFloat = .pi
    static let ROTATE_270: CGFloat = .pi * 1.5
    
    func rotated(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x, width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }

        return self
    }
    
    func fixedOrientation() -> UIImage? {
        if self.imageOrientation == UIImage.Orientation.up {
            return self
        }

        UIGraphicsBeginImageContext(self.size)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    /// up/down（mirredを含めて）以外の場合、不具合あり。
    /// でも、念のために残しておく。
    func fixed(orientation ori: UIImage.Orientation) -> UIImage {
        print("image orientation: \(imageOrientation.rawValue)")
        
        let image = self
        guard ori != .up else {
            return image
        }
        
        let size = image.size
        var transform: CGAffineTransform = .identity

        switch ori {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }

        // Flip image one more time if needed to, this is to prevent flipped image
        switch ori {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            break
        }
        
        guard var cgImage = image.cgImage else {
            fatalError()
        }
        
        autoreleasepool {
            var context: CGContext?
            
            guard let colorSpace = cgImage.colorSpace, let _context = CGContext(data: nil, width: Int(cgImage.width), height: Int(cgImage.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return
            }
            context = _context
            
            context?.concatenate(transform)

            var drawRect: CGRect = .zero
            switch imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                drawRect.size = CGSize(width: size.height, height: size.width)
            default:
                drawRect.size = CGSize(width: size.width, height: size.height)
            }

            context?.draw(cgImage, in: drawRect)
            
            guard let newCGImage = context?.makeImage() else {
                return
            }
            cgImage = newCGImage
        }
        
        let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        return uiImage
    }
    
    /// 画像にテキストを入れる
    /// - Parameters:
    ///   - text: テキスト
    ///   - color: テキスト色（基本値：黄色）
    ///   - font: Font（基本値：Helvetica Bold, size=50）
    ///   - text: テキスト
    ///   - to: 画像
    ///   - at: テキストの位置（画像内で）
    /// - Returns: 修正された画像
    class func draw(
        text: String,
        color textColor: UIColor = .yellow,
        font: UIFont? = nil,
        to image: UIImage,
        at point: CGPoint
    ) -> UIImage {
        let textFont = font ?? UIFont(name: "Helvetica Bold", size: 50)!

        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)

        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
        ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))

        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
}
