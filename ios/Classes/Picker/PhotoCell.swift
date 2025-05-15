import UIKit
import Photos
import AVKit


@available(iOS 14.0, *)
class PhotoCell: UICollectionViewCell {

    static let identifier = "PhotoCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let videoIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .white
        imageView.isHidden = true // Initially hidden
        return imageView
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .right
        label.isHidden = true // Initially hidden
        return label
    }()

    private let selectionNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.backgroundColor = UIColor(hex: "#FDD400")
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.isHidden = true // Initially hidden
        return label
    }()

    private var asset: PHAsset?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(videoIndicator)
        contentView.addSubview(durationLabel)
        contentView.addSubview(selectionNumberLabel)
        setupConstraints()

        // Add long-press gesture recognizer
//        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
//        self.addGestureRecognizer(longPressGesture)
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
        selectionNumberLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            videoIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            videoIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            videoIndicator.widthAnchor.constraint(equalToConstant: 30),
            videoIndicator.heightAnchor.constraint(equalToConstant: 30),

            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            selectionNumberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            selectionNumberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            selectionNumberLabel.widthAnchor.constraint(equalToConstant: 24),
            selectionNumberLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(with asset: PHAsset, selectionNumber: Int?) {
        self.asset = asset

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        // Load thumbnail for the asset
        manager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { [weak self] image, _ in
            self?.imageView.image = image
        }

        // Show video indicator and duration if the asset is a video
        if asset.mediaType == .video {
            videoIndicator.isHidden = false
            durationLabel.isHidden = false
            durationLabel.text = formattedDuration(for: asset.duration)
        } else {
            videoIndicator.isHidden = true
            durationLabel.isHidden = true
        }

        // Show selection number if the asset is selected
        if let selectionNumber = selectionNumber {
            selectionNumberLabel.isHidden = false
            selectionNumberLabel.text = "\(selectionNumber)"
        } else {
            selectionNumberLabel.isHidden = true
        }
    }

    private func formattedDuration(for duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }

    // MARK: - Long Press Gesture Handler
    @objc private func handleLongPress() {
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
        if let parentVC = self.parentViewController {
            parentVC.present(previewVC, animated: true, completion: nil)
        }
    }

    private func showVideoPreview(url: URL) {
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player

        if let parentVC = self.parentViewController {
            parentVC.present(playerVC, animated: true) {
                player.play()
            }
        }
    }

    // Helper to get the parent view controller
    private var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    func updateSelectionCounter(_ selectionNumber: Int?) {
        if let selectionNumber = selectionNumber {
            selectionNumberLabel.isHidden = false
            selectionNumberLabel.text = "\(selectionNumber)"
        } else {
            selectionNumberLabel.isHidden = true
        }
    }


}
