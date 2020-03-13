//
//  HeaderView.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/11/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import Kingfisher

class HeaderView: UIView {
// need to add the height
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = UIImage(named: "mic")
        return iv
    }()
    
    //  no longer need this init.
//    override init(frame: CGRect) {
//        super.init(coder)
//        commonInit()
//    }
    
    // make our own seperate initializer
    init(imageURL: String) {
              // the height is the height you want
          // the width is ...
          super.init(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        commonInit()
        imageView.kf.setImage(with: URL(string: imageURL))
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setUpImageViewConstraints()
        
    }
    
    private func setUpImageViewConstraints() {
        
        addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
    }


}
