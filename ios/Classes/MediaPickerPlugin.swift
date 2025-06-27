import Flutter
import UIKit
import AVFoundation

@available(iOS 14.0, *)
public class MediaPickerPlugin: NSObject, FlutterPlugin , FlutterStreamHandler{
    private var eventSink: FlutterEventSink?
    private var mediaPickerVC: PickerViewController?
    private var heightConstraint: NSLayoutConstraint?


  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "media_picker_channel", binaryMessenger: registrar.messenger())
      let eventChannel = FlutterEventChannel(name: "media_picker_events", binaryMessenger: registrar.messenger())

    let instance = MediaPickerPlugin()
      eventChannel.setStreamHandler(instance)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
case "downloadVideoFromiCloud":
    guard let args = call.arguments as? [String: Any],
          let assetId = args["assetId"] as? String,
          let path = args["path"] as? String
    else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        return
    }
    
    MediaDownloader.downloadMedia(
        assetLocalIdentifier: assetId,
        destinationPath: path
    ) { success, error in
        if success {
            result(path) // Return the same path if successful
        } else if let error = error {
            result(FlutterError(code: "DOWNLOAD_FAILED", message: error, details: nil))
        }
    }
    case "handleEvent":
      guard let args = call.arguments as? [String: Any]
      else {
        return
      }
        self.handleEvent(
        event: args, result: result)
    case "tryCompress":
            if let videoPath = call.arguments as? [String: Any],
                let path = videoPath["videoPath"] as? String
            {
                tryCompress(
                    videoPath: path,
                    completion: { finalVideoPath in
                        result(finalVideoPath)
                    })
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Video path is required", details: nil))
            }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
/////////////////////////
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    public func sendEvent(event: [String: Any]) {
        eventSink?(event)
    }
    
    public func handleEvent(event: [String: Any], result: @escaping FlutterResult) {
        guard let action = event["action"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing action", details: nil))
            return
        }
        
        switch action {
        case "showMediaPicker":
            guard let text = event["text"] as? String,let onlyPhotos = event["onlyPhotos"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing text", details: nil))
                return
            }
            showMediaPicker(text: text, result: result,onlyPhotos: onlyPhotos)
        case "hideMediaPicker":
            hideMediaPicker(result: result)
        case "reopenMediaPicker":
            reopenMediaPicker(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func showMediaPicker(text: String, result: @escaping FlutterResult, onlyPhotos : Bool ) {
        mediaPickerVC = PickerViewController(text: text,onlyPhotos: onlyPhotos)
        guard let mediaPickerVC = mediaPickerVC else {
            result(FlutterError(code: "UNAVAILABLE", message: "Unable to create media picker", details: nil))
            return
        }
        mediaPickerVC.onMediaSelected = { paths, inputText, method,thumbnails in
            let response: [String: Any] = [
                "event": "mediaSelected",
                "paths": paths,
                "thumbnails" : thumbnails,
                "controller": inputText,
                "method": method

            ]
            print("\(response)")
            self.sendEvent(event: response)
            
            if method == "edit" {
                self.hideMediaPicker(result: result)
            }
        }
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
   
             mediaPickerVC.modalPresentationStyle = .formSheet
//            mediaPickerVC.isModalInPresentation = true
            if #available(iOS 15.0, *) {
                if let sheet = mediaPickerVC.sheetPresentationController {
                    sheet.detents = [.medium(), .large()] // You can choose between .medium and .large
                    sheet.prefersGrabberVisible = true // Optional: Show a grabber at the top
                    sheet.preferredCornerRadius = 20 // Optional: Set corner radius
                }
                
                // Present the view controller as a sheet
                rootViewController.present(mediaPickerVC, animated: true, completion: {
                    result(true)
                })
            }

         } else {
             result(FlutterError(code: "UNAVAILABLE", message: "Unable to present media picker", details: nil))
         }
    }

    
    

    private func hideMediaPicker(result: @escaping FlutterResult) {
        if let mediaPickerVC = mediaPickerVC {
            mediaPickerVC.dismiss(animated: true, completion: {
//                  result(true)
              })
            sendEvent(event: ["event": "pickerHidden"])
            result(true)
        } else {
            result(FlutterError(code: "UNAVAILABLE", message: "Media picker not initialized", details: nil))
        }
    }
    
    private func reopenMediaPicker(result: @escaping FlutterResult) {
        if let mediaPickerVC = mediaPickerVC {
//            mediaPickerVC.view.isHidden = false
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                rootViewController.present(mediaPickerVC, animated: true, completion: {
                    result(true)
                })}
            mediaPickerVC.view.superview?.bringSubviewToFront(mediaPickerVC.view)
            print("----------2-------------------")
            sendEvent(event: ["event": "pickerReopened"])
            result(true)
        } else {
            result(FlutterError(code: "UNAVAILABLE", message: "Media picker not initialized", details: nil))
        }
    }
            func tryCompress(videoPath: String, completion: @escaping (String) -> Void) {
            DispatchQueue.global(qos: .userInitiated).async {
                let videoURL = URL(fileURLWithPath: videoPath)
                self.handleVideoCompressionIfNeeded(inputFile: videoURL) { finalVideoPath in
                    DispatchQueue.main.async {
                        completion(finalVideoPath ?? videoPath)
                    }
                }
            }
        }

    func handleVideoCompressionIfNeeded(inputFile: URL, completion: @escaping (String?) -> Void) {
        let sizeMB = getFileSizeMB(url: inputFile)

        // 1. Always skip <50MB
        if sizeMB < 50 {
            print("Video is \(sizeMB)MB, no compression needed.")
            completion(inputFile.path)
            return
        }

        let resolution = getVideoResolution(url: inputFile)
        let width = resolution.width
        let height = resolution.height
        let maxDimension = max(width, height)
        let minDimension = min(width, height)
        
        var presetName: String?
        var targetRes: Int = maxDimension // for print/debug

        if sizeMB > 1024 { // >1GB
            // Use 480p, the lowest available preset (no 360p on iOS)
            if minDimension <= 480 { presetName = nil }
            else { presetName = AVAssetExportPreset640x480; targetRes = 480 }
        } else if sizeMB > 200 { // 200MB–1GB
            if minDimension <= 480 { presetName = nil }
            else { presetName = AVAssetExportPreset640x480; targetRes = 480 }
        } else if sizeMB > 100 { // 100MB–200MB
            if minDimension <= 540 { presetName = nil }
            else { presetName = AVAssetExportPreset960x540; targetRes = 540 }
        } else if sizeMB > 50 { // 50MB–100MB
            if minDimension <= 720 { presetName = nil }
            else { presetName = AVAssetExportPreset1280x720; targetRes = 720 }
        }
        
        // If no preset, skip compression (either too small or already low-res)
        if presetName == nil {
            print("Video is already \(minDimension)p or less, skipping compression.")
            completion(inputFile.path)
            return
        }
        
        print("Compressing video (\(sizeMB)MB) to \(targetRes)p using preset \(presetName!)")
        compressVideo(inputURL: inputFile, presetName: presetName!) { compressedPath in
            completion(compressedPath)
        }
    }
        func presentHeavierCompressionPrompt(
            sizeMB: Double,
            completion: @escaping (Bool) -> Void
        ) {
            let alert = UIAlertController(
                title: "Large File (\(Int(sizeMB)) MB)",
                message:
                    "Do you want heavier compression to reduce file size? (Will degrade quality to ~480p)",
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(
                    title: "No, send as is", style: .default,
                    handler: { _ in
                        completion(false)
                    }))
            alert.addAction(
                UIAlertAction(
                    title: "Yes, compress more", style: .destructive,
                    handler: { _ in
                        completion(true)
                    }))
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                rootViewController.present(
                    alert, animated: true, completion: nil)
            }
        }

        func presentBigFileWarning(
            sizeMB: Double,
            completion: @escaping (Bool) -> Void
        ) {
            let alert = UIAlertController(
                title: "File is \(Int(sizeMB)) MB",
                message:
                    "This video is quite large (low res but potentially very long). Sending could take a while.",
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(
                    title: "Cancel", style: .cancel,
                    handler: { _ in
                        completion(false)
                    }))
            alert.addAction(
                UIAlertAction(
                    title: "Send Anyway", style: .default,
                    handler: { _ in
                        completion(true)
                    }))
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                rootViewController.present(
                    alert, animated: true, completion: nil)
            }
        }

        func compressVideo(
            inputURL: URL, presetName: String, completion: @escaping (String) -> Void
        ) {
            let asset = AVURLAsset(url: inputURL)

            guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName)
            else {
                print("Failed to create export session.")
                completion(inputURL.path)
                return
            }

            let outputFileName = "\(UUID().uuidString)_compressed.mp4"
            let outputURL = inputURL.deletingLastPathComponent().appendingPathComponent(
                outputFileName)

            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true

            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("Compression successful: \(outputURL.path)")
                    completion(outputURL.path)
                default:
                    print("Compression failed or cancelled, using original file.")
                    completion(inputURL.path)
                }
            }
        }

        func getVideoResolution(url: URL) -> (width: Int, height: Int) {
            let asset = AVAsset(url: url)
            guard let track = asset.tracks(withMediaType: .video).first else {
                return (0, 0)
            }
            let size = track.naturalSize.applying(track.preferredTransform)
            return (Int(abs(size.width)), Int(abs(size.height)))
        }

        func getFileSizeMB(url: URL) -> Double {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(
                    atPath: url.path)
                if let fileSize = fileAttributes[.size] as? NSNumber {
                    return fileSize.doubleValue / (1024.0 * 1024.0)
                }
            } catch {
                print("Error getting file size: \(error)")
            }
            return 0.0
        }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


}
