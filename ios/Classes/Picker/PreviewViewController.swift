//
//  PreviewViewController.swift
//  last picker
//
//  Created by Bashar Albashier on 18/02/2025.
//

import UIKit
import Photos

class PreviewViewController: UIViewController {

    var selectedPhotos: [PHAsset] = []

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        return scrollView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(scrollView)
        setupImages()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
    }

    private func setupImages() {
        for (index, asset) in selectedPhotos.enumerated() {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: CGFloat(index) * view.frame.width, y: 0, width: view.frame.width, height: view.frame.height)

            let manager = PHImageManager.default()
            manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { image, _ in
                imageView.image = image
            }

            scrollView.addSubview(imageView)
        }

        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(selectedPhotos.count), height: view.frame.height)
    }
}
