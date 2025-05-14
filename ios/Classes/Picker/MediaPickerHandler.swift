//
//  MediaPickerHandler.swift
//  Runner
//
//  Created by Bashar Albashier on 08/03/2025.
//

class MediaPickerEventChannelHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var mediaPickerVC: PickerViewController?
    private var heightConstraint: NSLayoutConstraint?
//    private var overlayView: UIView!
    // Called when Flutter starts listening to the event channel
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    // Called when Flutter stops listening to the event channel
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    // Send an event to Flutter
    public func sendEvent(event: [String: Any]) {
        eventSink?(event)
    }
    
    // Handle events from Flutter
    public func handleEvent(event: [String: Any], result: @escaping FlutterResult) {
        guard let action = event["action"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing action", details: nil))
            return
        }
        
        switch action {
        case "showMediaPicker":
            guard let text = event["text"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing text", details: nil))
                return
            }
            showMediaPicker(text: text, result: result)
            
        case "hideMediaPicker":
            hideMediaPicker(result: result)
            
        case "reopenMediaPicker":
            print("---------------1--------------")
            reopenMediaPicker(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func showMediaPicker(text: String, result: @escaping FlutterResult) {
        mediaPickerVC = PickerViewController(text: text)

        guard let mediaPickerVC = mediaPickerVC else {
            result(FlutterError(code: "UNAVAILABLE", message: "Unable to create media picker", details: nil))
            return
        }
  
        mediaPickerVC.onMediaSelected = { paths, inputText, method in
            let response: [String: Any] = [
                "event": "mediaSelected",
                "paths": paths,
                "controller": inputText,
                "method": method
            ]
            self.sendEvent(event: response)
            
            if method == "edit" {
                self.hideMediaPicker(result: result)
            }
        }
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
             // Set the modal presentation style to form sheet
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
             // Configure the sheet presentation controller (iOS 15+)
         
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
