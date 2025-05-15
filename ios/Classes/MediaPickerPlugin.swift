import Flutter
import UIKit

@available(iOS 14.0, *)
public class MediaPickerPlugin: NSObject, FlutterPlugin {
      private var mediaPickerVC: PickerViewController?
      private var mediaPickerEventChannelHandler =
        MediaPickerEventChannelHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "media_picker_plugin", binaryMessenger: registrar.messenger())
    let instance = MediaPickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showMediaPicker":
      guard let args = call.arguments as? [String: Any],
        let text = args["text"] as? String
      else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENTS",
            message: "Invalid arguments", details: nil))
        return
      }
      self.showMediaPicker(result: result, text: text)

    case "reopenMediaPicker":
      self.reopenMediaPicker(result: result)
    case "handleEvent":
      guard let args = call.arguments as? [String: Any],
        let text = args["text"] as? String
      else {
          print("no param")
//        result(
//          FlutterError(
//            code: "INVALID_ARGUMENTS",
//            message: "Invalid arguments", details: nil))
        return
      }
        print("param param")
      self.mediaPickerEventChannelHandler.handleEvent(
        event: args, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }



   private func reopenMediaPicker(result: @escaping FlutterResult) {
        if let mediaPickerVC = self.mediaPickerVC {
            // Unhide the PickerViewController
            mediaPickerVC.view.isHidden = false

            // Optionally, bring it to the front
            mediaPickerVC.view.superview?.bringSubviewToFront(
                mediaPickerVC.view)

            result(true)  // Indicate success
        } else {
            result(
                FlutterError(
                    code: "UNAVAILABLE",
                    message: "Media picker not initialized", details: nil))
        }
    }
    private func showMediaPicker(result: @escaping FlutterResult, text: String)
    {
        // Create an instance of your custom ViewController
        //        if mediaPickerVC == nil {
        mediaPickerVC = PickerViewController(text: text)
        //           }
        guard let mediaPickerVC = mediaPickerVC else {
            result(
                FlutterError(
                    code: "UNAVAILABLE",
                    message: "Unable to create media picker", details: nil))
            return
        }
        // Set a completion handler to return the selected media paths to Flutter
        mediaPickerVC.onMediaSelected = { paths, inputText, method in
            let response: [String: Any] = [
                "paths": paths,
                "controller": inputText,
                "method": method,
            ]
            if method == "edit" {
                mediaPickerVC.view.isHidden = true
            }
            result(response)
        }

        // Present the ViewController
       
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.addChild(mediaPickerVC)
            mediaPickerVC.view.translatesAutoresizingMaskIntoConstraints = false
            rootViewController.view.addSubview(mediaPickerVC.view)

            // Set constraints for half-screen
            NSLayoutConstraint.activate([
                rootViewController.view.leadingAnchor.constraint(
                    equalTo: rootViewController.view.leadingAnchor),
                mediaPickerVC.view.leadingAnchor.constraint(
                    equalTo: rootViewController.view.leadingAnchor),
                mediaPickerVC.view.trailingAnchor.constraint(
                    equalTo: rootViewController.view.trailingAnchor),
                mediaPickerVC.view.bottomAnchor.constraint(
                    equalTo: rootViewController.view.bottomAnchor),
                mediaPickerVC.view.heightAnchor.constraint(
                    equalTo: rootViewController.view.heightAnchor,
                    multiplier: 0.7),
            ])

            mediaPickerVC.didMove(toParent: rootViewController)
        } else {
            result(
                FlutterError(
                    code: "UNAVAILABLE",
                    message: "Unable to present media picker", details: nil))
        }
    }
}
