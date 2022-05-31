//
//  JpegImage.swift
//

import UIKit
import AVFoundation
import CoreLocation
import ImageIO
import Photos
import MobileCoreServices

struct ExifTiff {
    var model: String? = nil
    var maker: String? = nil
    var software: String? = nil
    var documentName: String? = nil
}

extension UIImage {
    /// 画像をJPEGフォーマットのファイルとして保存する。
    /// - Parameters:
    ///   - to: 画像ファイルのパス（URL）
    ///   - location: 位置情報（GPS）
    ///   - date: 撮影日時
    func writeJpeg(to url: URL, location: CLLocation?, date: Date = Date(), orgFilename: String? = nil) {
        guard let data = toJpegData(location: location, date: date) else {
            fatalError()
        }
        
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            print(error)
        }
    }
    
    /// 画像をJPEGフォーマットに変換。
    /// 位置情報をEXIFに追加し、EXIFにも色々情報を追加する。
    /// - Parameters:
    ///   - location: 位置情報（GPS）
    ///   - date: 撮影日時
    ///   - tiff: EXIFのTIFF情報（デバイス情報）
    /// - Returns: JPEGデータ
    func toJpegData(location: CLLocation? = nil, date: Date = Date(), tiff: ExifTiff? = nil) -> Data? {
        return autoreleasepool {
            let data = NSMutableData()

            let metadata = (CIImage(image: self)?.properties ?? [:] ) as NSDictionary
            let options = metadata.mutableCopy() as! NSMutableDictionary
            options[kCGImageDestinationLossyCompressionQuality] = CGFloat(0.5)

            // MARK: 位置情報を記録(GPS)
            if let location = location {
                let gpsData = NSMutableDictionary()

                let altitudeRef = Int(location.altitude < 0.0 ? 1 : 0)
                let latitudeRef = location.coordinate.latitude < 0.0 ? "S" : "N"
                let longitudeRef = location.coordinate.longitude < 0.0 ? "W" : "E"

                // GPS metadata
                gpsData[kCGImagePropertyGPSLatitude as String] = abs(location.coordinate.latitude)
                gpsData[kCGImagePropertyGPSLongitude as String] = abs(location.coordinate.longitude)
                gpsData[kCGImagePropertyGPSLatitudeRef as String] = latitudeRef
                gpsData[kCGImagePropertyGPSLongitudeRef as String] = longitudeRef
                gpsData[kCGImagePropertyGPSAltitude as String] = Int(abs(location.altitude))
                gpsData[kCGImagePropertyGPSAltitudeRef as String] = altitudeRef
                gpsData[kCGImagePropertyGPSTimeStamp as String] = location.timestamp
                gpsData[kCGImagePropertyGPSDateStamp as String] = location.timestamp
                gpsData[kCGImagePropertyGPSVersion as String] = "2.2.0.0"

                options[kCGImagePropertyGPSDictionary as String] = gpsData
            }
            
            // MARK: EXIF
            let orgExif = options[ kCGImagePropertyExifDictionary as String ] as? NSMutableDictionary
            let exif = orgExif ?? NSMutableDictionary()
            
            // 撮影日付を記録
            let dtofmt = DateFormatter();
            dtofmt.locale = Locale(identifier: "en_US_POSIX")
            dtofmt.dateFormat = "yyyy:MM:dd HH:mm:ss"
            exif[kCGImagePropertyExifDateTimeOriginal as String] = dtofmt.string(from: date)
            
            options[kCGImagePropertyExifDictionary as String] = exif
            
            // MARK: デバイス情報を記録(TIFF)
            let tiffData = NSMutableDictionary()
            tiffData[kCGImagePropertyTIFFMake as String] =  tiff?.maker ?? "Apple"
            
            if let software = tiff?.software {
                tiffData[kCGImagePropertyTIFFSoftware as String] = software
            }
            
            let modelName = UIDevice().model
            tiffData[kCGImagePropertyTIFFModel as String] = tiff?.model ?? modelName
            tiffData[kCGImagePropertyTIFFOrientation as String] = self.imageOrientation.rawValue
            
            // * 画像をiPhoneのアルバムに保存する場合、画像のファイル名は指定できない
            // よって、Windowsアプリ側で「ドキュメント」情報を確認し、本来のファイル名に変更するようにする
            if let orgFilename = tiff?.documentName {
                tiffData[kCGImagePropertyTIFFDocumentName as String] = orgFilename
            }
            
            options[kCGImagePropertyTIFFDictionary as String] = tiffData
            
            print("- TIFFModel: \(modelName)")
            print("- imageOrientation: \(imageOrientation.rawValue)")
            
            guard let newCgImage = self.cgImage?.resize(size: self.size) else {
                print("cgImage is Nil")
                return nil
            }
            
            guard let imageDestinationRef = CGImageDestinationCreateWithData(data as CFMutableData, kUTTypeJPEG, 1, nil)
            else {
                return nil
            }
            CGImageDestinationAddImage(imageDestinationRef, newCgImage, options)
            CGImageDestinationFinalize(imageDestinationRef)
            
            return data as Data
        }
    }
}

extension CGImage {
    /// cf. https://qiita.com/john-rocky/items/dfb6ca375a24e2ebd201
    func resize(size:CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)

        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel

        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else { return nil }

        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }
}
