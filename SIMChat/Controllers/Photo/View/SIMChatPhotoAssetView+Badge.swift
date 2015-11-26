//
//  SIMChatPhotoAssetView+Badge.swift
//  SIMChat
//
//  Created by sagesse on 11/22/15.
//  Copyright © 2015 Sagesse. All rights reserved.
//

import UIKit

///
/// 标记类型
///
enum SIMChatPhotoAssetBadgeStyle : Int {
    case None = 0
    
    case Image
    case Video
    case Audio
    
    case Camera
}

///
/// 标记
///
class SIMChatPhotoAssetBadgeView: SIMView {
    override func build() {
        super.build()
        
        iconView.frame = CGRectMake(0, 0, bounds.height, bounds.height)
        addSubview(iconView)
        
        backgroundLayer.frame = bounds
        backgroundLayer.colors = [UIColor.clearColor().CGColor, UIColor(white: 0, alpha: 0.8).CGColor]
        
        titleLabel.textAlignment = .Right
        titleLabel.textColor = .whiteColor()
        titleLabel.font = .systemFontOfSize(12)
        titleLabel.adjustsFontSizeToFitWidth = true
        
        layer.addSublayer(backgroundLayer)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = bounds
        iconView.frame = CGRectMake(0, 0, bounds.height, bounds.height)
        if titleLabel.superview != nil {
            titleLabel.frame = CGRectMake(bounds.height, 0, bounds.width - bounds.height - 4, bounds.height)
        }
    }
    
    // 显示类型
    var style: SIMChatPhotoAssetBadgeStyle = .None {
        didSet {
            // TODO: 需要加载/显示图片
        }
    }
    // 显示内容
    var content: String? {
        set {
            // 必须要有所改变才处理
            guard newValue != content else {
                return
            }
            // 只有存在内容的时候才显示
            if newValue?.isEmpty ?? true {
                if titleLabel.superview != nil {
                    titleLabel.removeFromSuperview()
                }
            } else {
                if titleLabel.superview != self {
                    addSubview(titleLabel)
                }
            }
            titleLabel.text = newValue
        }
        get { return titleLabel.text }
    }
    
    private lazy var iconView = UIImageView()
    private lazy var titleLabel = UILabel()
    private lazy var backgroundLayer = CAGradientLayer()
}
