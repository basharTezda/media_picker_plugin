//
//  ImagePreviewViewController.swift
//  last picker
//
//  Created by Bashar Albashier on 19/02/2025.
//

import UIKit

@available(iOS 14.0, *)
class ImagePreviewViewController: UIViewController {
    var onSend: (() -> Void)?
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return button
    }()

    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(imageView)
        view.addSubview(sendButton)

        // Add tap gesture to dismiss the preview
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPreview))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
        
        // Position the send button in top right corner
        let buttonSize: CGFloat = 44
        let padding: CGFloat = 16
        sendButton.frame = CGRect(
            x: view.bounds.width - buttonSize - padding,
            y: view.safeAreaInsets.top + padding,
            width: buttonSize,
            height: buttonSize
        )
    }

    @objc private func dismissPreview() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendButtonTapped() {
        onSend?()
    }
}
