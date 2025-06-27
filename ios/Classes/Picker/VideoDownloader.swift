import Photos
import AVFoundation
class MediaDownloader {
    static func downloadMedia(
        assetLocalIdentifier: String,
        destinationPath: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalIdentifier], options: nil)
        
        guard let asset = fetchResult.firstObject else {
            completion(false, "Asset not found id \(assetLocalIdentifier)")
            return
        }
        
        let fileURL = URL(fileURLWithPath: destinationPath)
        let directory = fileURL.deletingLastPathComponent()
        
        // Create directory if it doesn't exist
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            completion(false, "Failed to create directory: \(error.localizedDescription)")
            return
        }
        
        switch asset.mediaType {
        case .image:
            downloadImage(asset: asset, fileURL: fileURL, completion: completion)
        case .video:
            downloadVideo(asset: asset, fileURL: fileURL, completion: completion)
        default:
            completion(false, "Unsupported media type")
        }
    }
    
    private static func downloadImage(
        asset: PHAsset,
        fileURL: URL,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
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
        completion: @escaping (Bool, String?) -> Void
    ) {
        if let error = info?[PHImageErrorKey] as? Error {
            completion(false, "Image download failed: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = data else {
            completion(false, "Failed to fetch image data")
            return
        }
        
        do {
            try imageData.write(to: fileURL)
            completion(true, nil)
        } catch {
            completion(false, "Failed to save image: \(error.localizedDescription)")
        }
    }
    
    private static func downloadVideo(
        asset: PHAsset,
        fileURL: URL,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { (avAsset, _, info) in
            if let error = info?[PHImageErrorKey] as? Error {
                completion(false, "Video download failed: \(error.localizedDescription)")
                return
            }
            
            guard let avAsset = avAsset else {
                completion(false, "Failed to fetch AVAsset")
                return
            }
            
            exportVideo(avAsset: avAsset, destinationURL: fileURL, completion: completion)
        }
    }
    
    private static func exportVideo(
        avAsset: AVAsset,
        destinationURL: URL,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard let exportSession = AVAssetExportSession(
            asset: avAsset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            completion(false, "Failed to create export session")
            return
        }
        
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(true, nil)
                case .failed:
                    completion(false, exportSession.error?.localizedDescription ?? "Video export failed")
                case .cancelled:
                    completion(false, "Video export cancelled")
                default:
                    completion(false, "Unknown video export error")
                }
            }
        }
    }
}