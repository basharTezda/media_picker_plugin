//
//  FooterReusableView.swift
//  last picker
//
//  Created by Bashar Albashier on 18/02/2025.
//

import UIKit

class FooterReusableView: UICollectionReusableView {

    static let identifier = "FooterReusableView"

    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .lightGray
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }

    func configure(with count: Int) {
        label.text = "Selected: \(count)"
    }
}
