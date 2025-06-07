import AVFoundation
import Photos
import PhotosUI
import UIKit

@available(iOS 14.0, *)
class PickerViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    UITextFieldDelegate,
    PHPickerViewControllerDelegate
{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    }

    // MARK: - Properties
    private var collectionView: UICollectionView!
    private var assets: [PHAsset] = []  // Store both photos and videos
    public var selectedAssets: [PHAsset] = []
    private var footerContainer: UIView!
    private var backgroundView: UIView!
    private var textField: PaddedTextField!
    private var sendButton: UIButton!
    private var titleLabel: UILabel!
    private var paths: [String] = []
    private var footerContainerBottomConstraint: NSLayoutConstraint?
    private var collectviewContainerBottomConstraint: NSLayoutConstraint?
    var onMediaSelected: (([String], String, String) -> Void)?
    private var heightConstraint: NSLayoutConstraint?
    private var text: String
    private var permissionView: UIView!
    private var permissionLabel: UILabel!
    private var permissionButton: UIButton!
    private var font: String
    private var onlyPhotos: Bool
    private var loadingDialog: LoadingDialog?
    private var exportSessions: [AVAssetExportSession] = []
    private var imageRequests: [PHImageRequestID] = []
    private var isExportCancelled = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        requestPhotoLibraryAccess()
        addOverlayToParentView()
        setupBackground()
        setupTitle()
        setupPermissionRequestUI()
        checkPhotoLibraryPermission()
        setupCollectionView()
        setupFooter()
        textField.text = text

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Initializer
    init(text: String, onlyPhotos: Bool = true) {
        self.font = "Poppins-Regular"
        self.text = text
        self.onlyPhotos = onlyPhotos
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Permission UI
    private func setupPermissionRequestUI() {
        permissionView = UIView()
        permissionView.backgroundColor = .clear
        permissionView.isHidden = true  // Initially hidden
        view.addSubview(permissionView)

        permissionLabel = UILabel()
        permissionLabel.text = "PingTop has access to only selected photos and videos."
        permissionLabel.font = UIFont(name: self.font, size: 12)
        permissionLabel.textColor = .black
        permissionLabel.textAlignment = .left
        permissionLabel.numberOfLines = 0
        permissionView.addSubview(permissionLabel)

        permissionButton = UIButton(type: .system)
        permissionButton.setTitle("MANAGE", for: .normal)
        permissionButton.titleLabel?.font = UIFont(name: self.font, size: 16)
        permissionButton.setTitleColor(.white, for: .normal)
        permissionButton.backgroundColor = .black
        permissionButton.layer.cornerRadius = 16
        permissionButton.layer.masksToBounds = true
        permissionButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        permissionView.addSubview(permissionButton)

        // Constraints
        permissionView.translatesAutoresizingMaskIntoConstraints = false
        permissionLabel.translatesAutoresizingMaskIntoConstraints = false
        permissionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            permissionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            permissionView.heightAnchor.constraint(equalToConstant: 50),
            permissionView.widthAnchor.constraint(equalTo: view.widthAnchor),
            permissionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            permissionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            permissionLabel.topAnchor.constraint(equalTo: permissionView.topAnchor, constant: 16),
            permissionLabel.leadingAnchor.constraint(
                equalTo: permissionView.leadingAnchor, constant: 5),
            permissionLabel.trailingAnchor.constraint(
                equalTo: permissionView.trailingAnchor, constant: -150),

            permissionButton.topAnchor.constraint(equalTo: permissionView.topAnchor, constant: 16),
            permissionButton.trailingAnchor.constraint(
                equalTo: permissionView.trailingAnchor, constant: -5),
            permissionButton.widthAnchor.constraint(equalToConstant: 94),
            permissionButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    // MARK: - Open Settings
    @objc private func openSettings() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
            if newStatus == .limited {
                DispatchQueue.main.async {
                    self.showLimitedPhotoPicker()
                }
            }
        }
    }

    func showLimitedPhotoPicker() {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
    }

    func showAddMorePhotosButton() {
        let button = UIButton(type: .system)
        button.setTitle("Add More Photos", for: .normal)
        button.addTarget(self, action: #selector(openLimitedLibraryPicker), for: .touchUpInside)
        button.frame = CGRect(x: 100, y: 100, width: 200, height: 50)
        view.addSubview(button)
    }

    @objc func openLimitedLibraryPicker() {
        let alert = UIAlertController(
            title: "Full Photo Library Access Required",
            message:
                "Please grant full access to the photo library in Settings to select more photos.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(
            UIAlertAction(title: "Open Settings", style: .cancel) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                }
            })
        present(alert, animated: true, completion: nil)
    }

    func requestPhotoLibraryAccesss() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.checkPhotoLibraryPermission()
            }
        }
    }

    // MARK: - Keyboard
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey]
                as? TimeInterval
        else {
            return
        }
        let keyboardHeight = keyboardFrame.height
        UIView.animate(withDuration: duration) {
            self.collectviewContainerBottomConstraint?.constant = -keyboardHeight - 70
            self.footerContainerBottomConstraint?.constant =
                -keyboardHeight - (self.view.safeAreaInsets.bottom - 35)
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey]
                as? TimeInterval
        else {
            return
        }
        UIView.animate(withDuration: duration) {
            self.collectviewContainerBottomConstraint?.constant = -70
            self.footerContainerBottomConstraint?.constant = 0
            self.view.layoutIfNeeded()
        }
    }

    private func dismissVC() {
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }

    @objc public func cancelButtonTapped() {
        let alert = UIAlertController(
            title: "Cancel Selection",
            message: "Are you sure you want to cancel? Any selected media will be lost.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

        alert.addAction(
            UIAlertAction(
                title: "Yes", style: .destructive,
                handler: { _ in
                    self.dismiss(animated: true, completion: nil)
                    self.dismissVC()
                    self.dismissOverlay()
                }))

        if selectedAssets.isEmpty {
            self.dismiss(animated: true, completion: nil)
            self.dismissVC()
            self.dismissOverlay()
        } else {
            present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Background
    private func setupBackground() {
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
    }

    @objc private func additionalButtonTapped() {
        print("Action button tapped")
    }

    private func addOverlayToParentView() {
        guard let parentViewController = self.parent else {
            print("No parent view controller found")
            return
        }
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.frame = parentViewController.view.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parentViewController.view.addSubview(backgroundView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backgroundView.addGestureRecognizer(tapGesture)

        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeUpGesture.direction = .up
        backgroundView.addGestureRecognizer(swipeUpGesture)

        let swipeDownGesture = UISwipeGestureRecognizer(
            target: self, action: #selector(handleSwipe))
        swipeDownGesture.direction = .down
        backgroundView.addGestureRecognizer(swipeDownGesture)

        let swipeLeftGesture = UISwipeGestureRecognizer(
            target: self, action: #selector(handleSwipe))
        swipeLeftGesture.direction = .left
        backgroundView.addGestureRecognizer(swipeLeftGesture)

        let swipeRightGesture = UISwipeGestureRecognizer(
            target: self, action: #selector(handleSwipe))
        swipeRightGesture.direction = .right
        backgroundView.addGestureRecognizer(swipeRightGesture)
    }

    @objc private func handleTap() {
        print("Overlay tapped")
        self.cancelButtonTapped()
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        self.cancelButtonTapped()
    }

    @objc private func dismissOverlay() {
        // backgroundView.removeFromSuperview() if you want to remove it
    }

    // MARK: - Title
    private func setupTitle() {
        view.backgroundColor = .white
        titleLabel = UILabel()
        titleLabel.text = "Photos"
        titleLabel.font = UIFont(name: self.font, size: 16)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        view.addSubview(titleLabel)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Close", for: .normal)
        cancelButton.titleLabel?.font = UIFont(name: self.font, size: 16)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        view.addSubview(cancelButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
        ])
    }

    // MARK: - CollectionView
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = calculateItemSize()

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        collectionView.allowsMultipleSelection = !onlyPhotos  // This is important
        view.addSubview(collectionView)

        collectviewContainerBottomConstraint = collectionView.bottomAnchor.constraint(
            equalTo: view.bottomAnchor)
        collectviewContainerBottomConstraint?.isActive = true

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(
                equalTo: permissionView.isHidden
                    ? titleLabel.bottomAnchor : permissionView.bottomAnchor,
                constant: 16
            ),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func calculateItemSize() -> CGSize {
        let numberOfColumns: CGFloat = 3
        let totalSpacing: CGFloat = 0
        let width = (view.frame.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: width)
    }

    // MARK: - Footer
    private func setupFooter() {
        //        guard !onlyPhotos else { return }
        footerContainer = UIView()
        footerContainer.backgroundColor = .white
        footerContainer.isHidden = true  // Initially hidden
        view.addSubview(footerContainer)

        let editButton = UIButton(type: .system)
        editButton.setImage(UIImage(named: "edit"), for: .normal)
        editButton.tintColor = .black
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        footerContainer.addSubview(editButton)

        let selectionCountLabel = UILabel()
        selectionCountLabel.text = "0"
        selectionCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        selectionCountLabel.textColor = .black
        selectionCountLabel.textAlignment = .center
        selectionCountLabel.backgroundColor = UIColor(hex: "#FDD400")
        selectionCountLabel.layer.cornerRadius = 10
        selectionCountLabel.layer.masksToBounds = true
        selectionCountLabel.isHidden = true  // Initially hidden
        footerContainer.addSubview(selectionCountLabel)

        textField = PaddedTextField()
        textField.placeholder = "Message"
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 0.0
        textField.backgroundColor = UIColor(hex: "#dce0dd")
        textField.textColor = .black
        textField.font = UIFont(name: self.font, size: 16)
        textField.returnKeyType = .done
        textField.textPadding = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        textField.delegate = self

        if let placeholder = textField.placeholder {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.gray,
                .font: UIFont(name: self.font, size: 16) ?? UIFont.systemFont(ofSize: 16),
            ]
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder, attributes: attributes)
        }

        textField.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.addSubview(textField)

        sendButton = UIButton(type: .system)
        let planeImage = UIImage(
            systemName: "paperplane.fill",
            withConfiguration: UIImage.SymbolConfiguration(scale: .default)
        )?.withRenderingMode(.alwaysOriginal)
        // Rotate the image 90 degrees clockwise
        let rotatedImage = planeImage?.rotate(degrees: 45)
        sendButton.setImage(rotatedImage, for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = UIColor(hex: "#FDD400")
        sendButton.layer.cornerRadius = 20
        sendButton.layer.masksToBounds = true
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        footerContainer.addSubview(sendButton)

        footerContainer.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        selectionCountLabel.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        footerContainerBottomConstraint = footerContainer.bottomAnchor.constraint(
            equalTo: view.bottomAnchor)
        footerContainerBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerContainer.heightAnchor.constraint(equalToConstant: 90),

            editButton.leadingAnchor.constraint(
                equalTo: footerContainer.leadingAnchor, constant: 16),
            editButton.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 32),
            editButton.heightAnchor.constraint(equalToConstant: 32),

            selectionCountLabel.trailingAnchor.constraint(
                equalTo: editButton.trailingAnchor, constant: 8),
            selectionCountLabel.topAnchor.constraint(equalTo: editButton.topAnchor, constant: -8),
            selectionCountLabel.widthAnchor.constraint(equalToConstant: 20),
            selectionCountLabel.heightAnchor.constraint(equalToConstant: 20),

            textField.leadingAnchor.constraint(equalTo: editButton.trailingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 32),

            sendButton.trailingAnchor.constraint(
                equalTo: footerContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Update Footer
    private func updateFooterVisibility() {
        guard !onlyPhotos else { return }
        footerContainer.isHidden = selectedAssets.isEmpty
    }

    func convertPHAssetToUIImage(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact

        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { (image, info) in
            completion(image)
        }
    }

    @objc private func editButtonTapped() {
        copySelectedMediaToTemporaryDirectory(method: "edit")
    }

    @objc private func sendButtonTapped() {
        self.dismiss(animated: true, completion: nil)
        self.dismissVC()
        self.dismissOverlay()
        copySelectedMediaToTemporaryDirectory(method: "send")
    }

    func copyVideoToDocuments(sourceURL: URL, completion: @escaping (URL?) -> Void) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first!

        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "\(timestamp)_\(sourceURL.lastPathComponent)"
        let destinationURL = documentsDirectory.appendingPathComponent(uniqueFileName)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            completion(destinationURL)
        } catch {
            print("Error copying file: \(error)")
            completion(nil)
        }
    }

    func getLocalPathFromPHAsset(asset: PHAsset) -> String? {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true

        var filePath: String?
        let semaphore = DispatchSemaphore(value: 0)

        manager.requestImageDataAndOrientation(for: asset, options: options) { (data, _, _, info) in
            if let fileUrl = info?["PHImageFileURLKey"] as? URL {
                filePath = fileUrl.path
            }
            semaphore.signal()
        }

        semaphore.wait()
        return filePath
    }

    // MARK: - Copy Selected Media
    private func copySelectedMediaToTemporaryDirectory(method: String) {
        showLoadingDialog()
        self.paths.removeAll()
        self.isExportCancelled = false
        self.exportSessions.removeAll()
        self.imageRequests.removeAll()

        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
        let totalAssets = selectedAssets.count
        var processedCount = 0

        for asset in selectedAssets {
            if isExportCancelled {
                break
            }

            if asset.mediaType == .image {
                let requestId = processImageAsset(asset, temporaryDirectory: temporaryDirectory) { [weak self] success in
                    processedCount += 1
                    self?.updateProgress(Float(processedCount) / Float(totalAssets))
                    
                    if processedCount == totalAssets && !(self?.isExportCancelled ?? false) {
                        self?.exportCompleted(method: method)
                    }
                }
                imageRequests.append(requestId)
            } else if asset.mediaType == .video {
                processVideoAsset(asset, temporaryDirectory: temporaryDirectory) { [weak self] success in
                    processedCount += 1
                    self?.updateProgress(Float(processedCount) / Float(totalAssets))
                    
                    if processedCount == totalAssets && !(self?.isExportCancelled ?? false) {
                        self?.exportCompleted(method: method)
                    }
                }
            }
        }
    }
    private func processImageAsset(_ asset: PHAsset, temporaryDirectory: URL, completion: @escaping (Bool) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .original
        
        return PHImageManager.default().requestImageDataAndOrientation(
            for: asset,
            options: options
        ) { [weak self] (data, _, _, info) in
            guard let self = self, !self.isExportCancelled, let data = data else {
                completion(false)
                return
            }

            let tempURL = temporaryDirectory.appendingPathComponent(UUID().uuidString + ".webp")
            do {
                try data.write(to: tempURL)
                self.paths.append(tempURL.path)
                completion(true)
            } catch {
                print("Failed to save image: \(error)")
                completion(false)
            }
        }
    }
    
    private func processVideoAsset(_ asset: PHAsset, temporaryDirectory: URL, completion: @escaping (Bool) -> Void) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .mediumQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current

        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { [weak self] (avAsset, _, info) in
            guard let self = self, !self.isExportCancelled else {
                completion(false)
                return
            }

            if let error = info?[PHImageErrorKey] as? Error {
                print("Video download failed: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let avAsset = avAsset else {
                print("Failed to fetch AVAsset")
                completion(false)
                return
            }

            self.exportVideoAsset(avAsset, to: temporaryDirectory, completion: completion)
        }
    }
    
    private func exportVideoAsset(_ asset: AVAsset, to directory: URL, completion: @escaping (Bool) -> Void) {
        // 1. Use faster preset for most cases
        let preset: String
        if #available(iOS 13.0, *), asset.isExportable {
            // Use HEVC if device supports it for better compression
            preset = AVAssetExportPresetHEVCHighestQuality
        } else {
            // Fallback to balanced quality/speed preset
            preset = AVAssetExportPreset1920x1080
        }
        
        // 2. Early validation
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            completion(false)
            return
        }
        
        // 3. Configure for faster export
        exportSession.outputURL = directory.appendingPathComponent(UUID().uuidString + ".mp4")
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true  // Better compression
        exportSession.timeRange = CMTimeRange(start: .zero, duration: asset.duration)  // Export full video
        
        // 4. Remove from sessions when done
        exportSessions.append(exportSession)
        
        // 5. Progress handler for debugging
//        if #available(iOS 11.0, *) {
//            exportSession.progressHandler = { progress in
//                print("Export progress: \(progress * 100)%")
//            }
//        }
        
        // 6. Start export
        exportSession.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                // Remove session when done
                self?.exportSessions.removeAll { $0 == exportSession }
                
                switch exportSession.status {
                case .completed:
                    if let outputURL = exportSession.outputURL {
                        self?.paths.append(outputURL.path)
                        completion(true)
                    } else {
                        completion(false)
                    }
                case .failed, .cancelled:
                    print("Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                default:
                    completion(false)
                }
            }
        }
    }
    
    private func showLoadingDialog() {
        loadingDialog = LoadingDialog()
        loadingDialog?.modalPresentationStyle = .overCurrentContext
        loadingDialog?.modalTransitionStyle = .crossDissolve
        loadingDialog?.cancelHandler = { [weak self] in
            self?.cancelExport()
        }
        present(loadingDialog!, animated: true)
    }
    
    private func updateProgress(_ progress: Float) {
        DispatchQueue.main.async {
            self.loadingDialog?.updateProgress(progress)
        }
    }
    
    private func updateMessage(_ message: String) {
        DispatchQueue.main.async {
            self.loadingDialog?.updateMessage(message)
        }
    }
    
    private func cancelExport() {
        isExportCancelled = true
        
        // Cancel all export sessions
        for session in exportSessions {
            session.cancelExport()
        }
        
        // Cancel all image requests
        for requestId in imageRequests {
            PHImageManager.default().cancelImageRequest(requestId)
        }
        
        // Clear all
        exportSessions.removeAll()
        imageRequests.removeAll()
        
        // Hide loading
        DispatchQueue.main.async {
            self.loadingDialog?.dismiss(animated: true) {
                self.loadingDialog = nil
            }
        }
    }
    
    private func exportCompleted(method: String) {
        DispatchQueue.main.async {
            self.loadingDialog?.dismiss(animated: true) {
                self.loadingDialog = nil
                
                let inputText = self.textField.text ?? ""
                self.onMediaSelected?(self.paths, inputText, method)

                if method == "send" {
                    self.dismiss(animated: true, completion: nil)
                    self.dismissVC()
                    self.dismissOverlay()
                }
            }
        }
    }
    func copyAndCompressImageToDocuments(
        sourceURL: URL,
        compressionQuality: CGFloat = 0.7,
        completion: @escaping (URL?) -> Void
    ) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first!

        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "\(timestamp)_\(sourceURL.lastPathComponent)"
        let destinationURL = documentsDirectory.appendingPathComponent(uniqueFileName)

        do {
            guard let sourceImage = UIImage(contentsOfFile: sourceURL.path) else {
                print("Error loading image")
                completion(nil)
                return
            }
            if let compressedImageData = sourceImage.jpegData(
                compressionQuality: compressionQuality)
            {
                try compressedImageData.write(to: destinationURL)
                completion(destinationURL)
            } else {
                print("Error compressing image")
                completion(nil)
            }
        } catch {
            print("Error copying and compressing image: \(error)")
            completion(nil)
        }
    }

    private func exportVideo(
        asset: PHAsset,
        to destinationDirectory: URL,
        completion: @escaping () -> Void
    ) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .original

        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { [weak self] (avAsset, _, info) in
            guard let self = self else {
                completion()
                return
            }

            if let error = info?[PHImageErrorKey] as? Error {
                print("Video download failed: \(error.localizedDescription)")
                completion()
                return
            }

            guard let avAsset = avAsset else {
                print("Failed to fetch AVAsset")
                completion()
                return
            }

            self.exportVideoAsset(avAsset, to: destinationDirectory) {
                completion()  // This will be called when the export is truly complete
            }
        }
    }

    private func exportVideoAsset(
        _ asset: AVAsset, to directory: URL, completion: @escaping () -> Void
    ) {
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            print("Failed to create export session")
            completion()
            return
        }

        let outputURL = directory.appendingPathComponent(UUID().uuidString + ".mp4")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    self.paths.append(outputURL.path)
                    print("Video exported successfully: \(outputURL.path)")
                case .failed, .cancelled:
                    if let error = exportSession.error {
                        print("Video export failed: \(error.localizedDescription)")
                    }
                default:
                    break
                }
                completion()
            }
        }
    }

    // MARK: - Permissions
    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Permission granted: \(status)")
                    self.fetchMedia()
                case .denied, .restricted, .notDetermined:
                    print("Permission not granted: \(status)")
                case .limited:
                    print("Limited permission granted: \(status)")
                @unknown default:
                    break
                }
            }
        }
    }

    func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in }
        case .restricted:
            print("Permission restricted (e.g., parental controls).")
        case .denied:
            print("Permission denied by the user.")
        case .authorized:
            print("Full access granted.")
        case .limited:
            self.permissionView.isHidden = false
            print("Limited access granted.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }

    // MARK: - Fetch Media
    private func fetchMedia() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        if onlyPhotos {
            fetchOptions.predicate = NSPredicate(
                format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        }
        let result = PHAsset.fetchAssets(with: fetchOptions)
        result.enumerateObjects { (asset, _, _) in
            self.assets.append(asset)
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Permission Denied",
            message: "Please enable photo library access in Settings to use this feature.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    private func updateSelectionCountLabel() {
        guard
            let selectionCountLabel = footerContainer.subviews.compactMap({ $0 as? UILabel }).first
        else {
            return
        }
        if selectedAssets.isEmpty {
            selectionCountLabel.isHidden = true
        } else {
            selectionCountLabel.isHidden = false
            selectionCountLabel.text = "\(selectedAssets.count)"
        }
    }

    func updateVisibleCellsSelectionCounters(in collectionView: UICollectionView) {
        for cell in collectionView.visibleCells {
            if let photoCell = cell as? PhotoCell,
                let indexPath = collectionView.indexPath(for: photoCell)
            {
                let asset = assets[indexPath.item]
                let selectionNumber = selectedAssets.firstIndex(of: asset).map { $0 + 1 }
                photoCell.updateSelectionCounter(selectionNumber)
            }
        }
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return assets.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PhotoCell.identifier,
                for: indexPath
            ) as? PhotoCell
        else {
            return UICollectionViewCell()
        }
        let asset = assets[indexPath.item]
        let selectionNumber = selectedAssets.firstIndex(of: asset).map { $0 + 1 }
        cell.configure(with: asset, selectionNumber: selectionNumber)
        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = assets[indexPath.item]
         
         if onlyPhotos {
             selectedAssets = [asset]
             copySelectedMediaToTemporaryDirectory(method: "send")
         } else {
             if let index = selectedAssets.firstIndex(of: asset) {
                 // Deselect the item
                 selectedAssets.remove(at: index)
                 collectionView.deselectItem(at: indexPath, animated: true)
             } else {
                 // Select the item
                 selectedAssets.append(asset)
             }
             updateVisibleCellsSelectionCounters(in: collectionView)
         }
         
         updateFooterVisibility()
         updateSelectionCountLabel()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
    {
        let asset = assets[indexPath.item]
        selectedAssets.removeAll { $0 == asset }
        updateVisibleCellsSelectionCounters(in: collectionView)
        updateFooterVisibility()
        updateSelectionCountLabel()
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.rotate(by: radians)
            draw(
                in: CGRect(
                    x: -size.width / 2,
                    y: -size.height / 2,
                    width: size.width,
                    height: size.height)
            )
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return rotatedImage ?? self
        }
        return self
    }
}

// MARK: - UIColor Extensions
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - LoadingOverlay
@available(iOS 14.0, *)
class LoadingOverlay {
    static let shared = LoadingOverlay()
    
    private var overlayView = UIView()
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var messageLabel = UILabel()
    
    private init() {
        configureOverlay()
    }
    
    private func configureOverlay() {
        // Setup overlay view
        overlayView.frame = UIScreen.main.bounds
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Setup activity indicator
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup message label
        messageLabel.text = "Preparing your media..."
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        overlayView.addSubview(activityIndicator)
        overlayView.addSubview(messageLabel)
        
        // Center the indicator and position label below it
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            messageLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: overlayView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: overlayView.trailingAnchor, constant: -20)
        ])
    }
    
    func show(over view: UIView, withMessage message: String? = nil) {
        overlayView.frame = view.bounds
        if let message = message {
            messageLabel.text = message
        }
        view.addSubview(overlayView)
        activityIndicator.startAnimating()
    }
    
    func hide() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
    }
    
    // Optional: Update message while showing
    func updateMessage(_ message: String) {
        messageLabel.text = message
    }
}

// MARK: - PaddedTextField
class PaddedTextField: UITextField {
    var textPadding = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textPadding)
    }
}

@available(iOS 14.0, *)
class LoadingDialog: UIViewController {
    private let containerView = UIView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    
    var cancelHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        activityIndicator.color = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicator)
        
        messageLabel.text = "Preparing your media..."
        messageLabel.textColor = .black
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .lightGray
        progressView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressView)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 280),
            
            activityIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            progressView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func cancelTapped() {
        cancelHandler?()
        dismiss(animated: true)
    }
    
    func updateProgress(_ progress: Float) {
        progressView.setProgress(progress, animated: true)
    }
    
    func updateMessage(_ message: String) {
        messageLabel.text = message
    }
}


extension UIImage {
    func rotate(degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
            
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return rotatedImage ?? self
        }
        return self
    }
}
