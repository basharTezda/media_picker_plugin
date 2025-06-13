import Photos
import AVFoundation

class MediaDownloader {
    static func downloadMedia(
        assetLocalIdentifier: String,
        completion: @escaping (String?, String?) -> Void
    ) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalIdentifier], options: nil)
        
        guard let asset = fetchResult.firstObject else {
            completion(nil, "Asset not found id \(assetLocalIdentifier)")
            return
        }
        
        // Create media directory if needed
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let mediaDirectory = documentsURL.appendingPathComponent("DownloadedMedia")
        
        do {
            try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            completion(nil, "Failed to create media directory: \(error.localizedDescription)")
            return
        }
        
        switch asset.mediaType {
        case .image:
            downloadImage(asset: asset, directory: mediaDirectory, completion: completion)
        case .video:
            downloadVideo(asset: asset, directory: mediaDirectory, completion: completion)
        default:
            completion(nil, "Unsupported media type")
        }
    }
    
    private static func downloadImage(
        asset: PHAsset,
        directory: URL,
        completion: @escaping (String?, String?) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        let filename: String
        if let creationDate = asset.creationDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            filename = "IMG_\(formatter.string(from: creationDate)).jpg"
        } else {
            filename = "IMG_\(UUID().uuidString.prefix(8)).jpg"
        }
        
        let fileURL = directory.appendingPathComponent(filename)
        
        // Use iOS version-appropriate method
        if #available(iOS 13.0, *) {
            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { (data, _, _, info) in
                handleImageData(data: data, fileURL: fileURL, info: info, completion: completion)
            }
        } else {
            PHImageManager.default().requestImageData(
                for: asset,
                options: options
            ) { (data, _, _, info) in
                handleImageData(data: data, fileURL: fileURL, info: info, completion: completion)
            }
        }
    }
    
    private static func handleImageData(
        data: Data?,
        fileURL: URL,
        info: [AnyHashable: Any]?,
        completion: @escaping (String?, String?) -> Void
    ) {
        if let error = info?[PHImageErrorKey] as? Error {
            completion(nil, "Image download failed: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = data else {
            completion(nil, "Failed to fetch image data")
            return
        }
        
        do {
            try imageData.write(to: fileURL)
            completion(fileURL.path, nil)
        } catch {
            completion(nil, "Failed to save image: \(error.localizedDescription)")
        }
    }
    
    private static func downloadVideo(
        asset: PHAsset,
        directory: URL,
        completion: @escaping (String?, String?) -> Void
    ) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        
        let filename: String
        if let creationDate = asset.creationDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            filename = "VID_\(formatter.string(from: creationDate)).mp4"
        } else {
            filename = "VID_\(UUID().uuidString.prefix(8)).mp4"
        }
        
        let fileURL = directory.appendingPathComponent(filename)
        
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { (avAsset, _, info) in
            if let error = info?[PHImageErrorKey] as? Error {
                completion(nil, "Video download failed: \(error.localizedDescription)")
                return
            }
            
            guard let avAsset = avAsset else {
                completion(nil, "Failed to fetch AVAsset")
                return
            }
            
            exportVideo(avAsset: avAsset, destinationURL: fileURL, completion: completion)
        }
    }
    
    private static func exportVideo(
        avAsset: AVAsset,
        destinationURL: URL,
        completion: @escaping (String?, String?) -> Void
    ) {
        guard let exportSession = AVAssetExportSession(
            asset: avAsset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            completion(nil, "Failed to create export session")
            return
        }
        
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(destinationURL.path, nil)
                case .failed:
                    completion(nil, exportSession.error?.localizedDescription ?? "Video export failed")
                case .cancelled:
                    completion(nil, "Video export cancelled")
                default:
                    completion(nil, "Unknown video export error")
                }
            }
        }
    }
}
