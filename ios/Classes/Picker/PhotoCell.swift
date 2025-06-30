import UIKit
import Photos
import AVKit

@available(iOS 14.0, *)
class PhotoCell: UICollectionViewCell {
    
    static let identifier = UUID().uuidString
    private(set) var thumbnailPath: String?
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    
    private let videoIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .white
        imageView.isHidden = true
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.masksToBounds = false
        imageView.clipsToBounds = false
        return imageView
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .right
        label.isHidden = true
        
        // Shadow configuration (matching the circle's shadow)
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 0)
        label.layer.shadowRadius = 3
        label.layer.shadowOpacity = 0.5
        
        // For text labels, you might also want to use the text-specific shadow properties
        label.shadowColor = UIColor.black.withAlphaComponent(0.5)
        label.shadowOffset = CGSize(width: 0, height: 0)
        
        return label
    }()
    
private let selectionCircle: UIView = {
    let view = UIView()
    view.layer.cornerRadius = 12
    view.layer.borderWidth = 2
    view.layer.borderColor = UIColor.white.cgColor
    view.backgroundColor = .clear
    view.isHidden = true
    
    // Shadow configuration
    view.layer.shadowColor = UIColor.black.cgColor  // Shadow color
    view.layer.shadowOffset = CGSize(width: 0, height: 0)  // Shadow offset
    view.layer.shadowRadius = 3  // Shadow blur radius
    view.layer.shadowOpacity = 0.5  // Shadow opacity (0 to 1)
    
    return view
}()
    
    private let selectionNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.backgroundColor = UIColor(hex: "#FDD400")
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()
    
    private var asset: PHAsset?
    var onMediaSaved: ((UIImage, String, String) -> Void)? // thumbnail, path, mediaType
    private var currentRequestID: PHImageRequestID?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if let requestID = currentRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
            currentRequestID = nil
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(videoIndicator)
        contentView.addSubview(durationLabel)
        contentView.addSubview(selectionCircle)
        contentView.addSubview(selectionNumberLabel)
        setupConstraints()
        
        // Add tap gesture for the entire cell (excluding circle area)
        let cellTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCellTap))
        self.addGestureRecognizer(cellTapGesture)
        
        // Add tap gesture specifically for the selection circle
        let circleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCircleTap))
        selectionCircle.addGestureRecognizer(circleTapGesture)
        selectionNumberLabel.addGestureRecognizer(circleTapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds
    }
    
    private func setupConstraints() {
        videoIndicator.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionCircle.translatesAutoresizingMaskIntoConstraints = false
        selectionNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            videoIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            videoIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            videoIndicator.widthAnchor.constraint(equalToConstant: 30),
            videoIndicator.heightAnchor.constraint(equalToConstant: 30),
            
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            selectionCircle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            selectionCircle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            selectionCircle.widthAnchor.constraint(equalToConstant: 24),
            selectionCircle.heightAnchor.constraint(equalToConstant: 24),
            
            selectionNumberLabel.centerXAnchor.constraint(equalTo: selectionCircle.centerXAnchor),
            selectionNumberLabel.centerYAnchor.constraint(equalTo: selectionCircle.centerYAnchor),
            selectionNumberLabel.widthAnchor.constraint(equalToConstant: 24),
            selectionNumberLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    func generateHighQualityThumbnail(completion: @escaping (String?) -> Void) {
//        guard let asset = self.asset else {
//            completion(nil)
//            return
//        }
//        
        if let image = self.imageView.image {
            if let imagePath = self.saveImageToTemporaryDirectory(image: image) {
                self.thumbnailPath = imagePath
                completion(imagePath)
            } else {
                completion(nil)
            }
        }else{
            completion(nil)
        }
//        let options = PHImageRequestOptions()
//        options.isSynchronous = false
//        options.deliveryMode = .highQualityFormat
//        options.isNetworkAccessAllowed = true
//        
//        PHImageManager.default().requestImage(
//            for: asset,
//            targetSize: PHImageManagerMaximumSize,
//            contentMode: .aspectFit,
//            options: options
//        ) { [weak self] image, _ in
//            guard let self = self, let image = image else {
//                completion(nil)
//                return
//            }
//            
//           
//        }
    }
    
    func configure(with asset: PHAsset, selectionNumber: Int?) {
        self.asset = asset
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        let targetSize = CGSize(width: 200, height: 200)
        
        currentRequestID = manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            guard let self = self else { return }
            self.imageView.image = image
            
            // Store the thumbnail image if this is the first load

        }
        
        // Video-specific setup
        if asset.mediaType == .video {
            videoIndicator.isHidden = false
            durationLabel.isHidden = false
            durationLabel.text = formattedDuration(for: asset.duration)
        } else {
            videoIndicator.isHidden = true
            durationLabel.isHidden = true
        }
        
        updateSelectionCounter(selectionNumber)
    }
    private func handleMediaReady(asset: PHAsset, thumbnail: UIImage?) {
        guard let thumbnail = thumbnail else { return }
        
        if asset.mediaType == .image {
            saveImageMedia(asset: asset, thumbnail: thumbnail)
        } else if asset.mediaType == .video {
            saveVideoMedia(asset: asset, thumbnail: thumbnail)
        }
    }
    
    private func saveImageMedia(asset: PHAsset, thumbnail: UIImage) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            guard let self = self, let image = image else { return }
            
            if let imagePath = self.saveImageToTemporaryDirectory(image: image) {
                self.onMediaSaved?(thumbnail, imagePath, "image")
            }
        }
    }
    
    private func saveVideoMedia(asset: PHAsset, thumbnail: UIImage) {
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { [weak self] (avAsset, _, _) in
            guard let self = self else { return }
            
            if let urlAsset = avAsset as? AVURLAsset {
                // Video is already in file system
                self.onMediaSaved?(thumbnail, urlAsset.url.path, "video")
                if let imagePath = self.saveImageToTemporaryDirectory(image: thumbnail) {
               
                    self.onMediaSaved?(thumbnail, imagePath, "image")
                }
            } else if let composition = avAsset as? AVComposition {
                // Need to export (for slow-motion videos, etc.)
                self.exportVideo(asset: composition, thumbnail: thumbnail)
            }
        }
    }
    
    private func exportVideo(asset: AVAsset, thumbnail: UIImage) {
        let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        )!
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously { [weak self] in
            guard let self = self else { return }
            
            if exportSession.status == .completed {
                if let imagePath = self.saveImageToTemporaryDirectory(image: thumbnail) {
                    self.onMediaSaved?(thumbnail, imagePath, "image")
                }
                self.onMediaSaved?(thumbnail, outputURL.path, "video")
            }
        }
    }
    
    private func saveImageToTemporaryDirectory(image: UIImage) -> String? {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
                self.thumbnailPath = fileURL.path
                print(" image picking: \(fileURL.path)")
                return fileURL.path
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
        return nil
    }
    
    private func formattedDuration(for duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
    @objc private func handleCircleTap() {
        // Notify the collection view to handle selection
        guard let collectionView = self.superview as? UICollectionView,
              let indexPath = collectionView.indexPath(for: self) else { return }
        
        if collectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            // If already selected, deselect it
            collectionView.deselectItem(at: indexPath, animated: true)
            collectionView.delegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
        } else {
//            guard let asset = self.asset else { return }
//            self.handleMediaReady(asset: asset, thumbnail: self.imageView.image)
            // If not selected, select it
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
      
        }
    }
    @objc private func handleCellTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
           
           // Check if tap was inside the circle area
           let circleFrame = selectionCircle.frame.insetBy(dx: -10, dy: -10) // Add some padding
           if circleFrame.contains(location) {
               self.handleCircleTap()
               return // Let circleTapGesture handle this
           }
           
        guard let asset = asset else { return }

        if asset.mediaType == .image {
            // Handle image preview
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat

            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { [weak self] image, _ in
                guard let self = self, let image = image else { return }
                self.showImagePreview(image: image)
            }
        } else if asset.mediaType == .video {
            // Handle video preview
            let options = PHVideoRequestOptions()
            options.version = .original

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] (avAsset, _, _) in
                guard let self = self, let avAsset = avAsset as? AVURLAsset else { return }
                self.showVideoPreview(url: avAsset.url)
            }
        }
    }
    private func showImagePreview(image: UIImage) {
        let previewVC = ImagePreviewViewController(image: image)
        if let parentVC = self.findViewController() {
            parentVC.present(previewVC, animated: true, completion: nil)
        }
    }

    private func showVideoPreview(url: URL) {
        DispatchQueue.main.async {
            let player = AVPlayer(url: url)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            
            // Get the parent view controller by traversing the responder chain
            if let parentVC = self.findViewController() {
                parentVC.present(playerVC, animated: true) {
                    player.play()
                }
            } else {
                print("Error: Could not find a view controller to present the player")
                // Handle the error case appropriately
            }
        }
    }
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let currentResponder = responder {
            if let viewController = currentResponder as? UIViewController {
                return viewController
            }
            responder = currentResponder.next
        }
        return nil
    }

    
    func updateSelectionCounter(_ selectionNumber: Int?) {
        if let selectionNumber = selectionNumber {
            selectionCircle.isHidden = true
            selectionNumberLabel.isHidden = false
            selectionNumberLabel.text = "\(selectionNumber)"
        } else {
            selectionCircle.isHidden = false
            selectionNumberLabel.isHidden = true
        }
    }

}
