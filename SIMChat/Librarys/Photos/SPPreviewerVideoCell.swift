//
//  SPPreviewerVideoCell.swift
//  SIMChat
//
//  Created by sagesse on 26/10/2016.
//  Copyright © 2016 sagesse. All rights reserved.
//

import UIKit

internal class SPPreviewerVideoCell: SPPreviewerCell {
    
    override var photo: SPAsset? {
        willSet {
            //_videoView.thumbnailImage = newValue?.image?.withOrientation(orientation)
            //_videoView.stop()
            
            _player.stop()
            
            newValue?.playerItem { [weak self] item in
                guard let item = item else {
                    return
                }
                self?._player.item = item
            }
        }
    }
    
    override var contentView: UIView {
        return _playerView
    }
    
    override func containterViewDidEndRotationing(_ containterView: SPContainterView, with view: UIView?, atOrientation orientation: UIImageOrientation) {
        super.containterViewDidEndRotationing(containterView, with: view, atOrientation: orientation)
        /// 更新图片
        //_videoView.thumbnailImage = _videoView.thumbnailImage?.withOrientation(orientation)
    }
    
    func playAndStop(_ sender: UIButton) {
        
        if _player.status.isPlayed {
            _player.stop()
        } else {
            _player.play()
        }
    }
    
    private func _init() {
        
        let button = UIButton()
        
        button.setTitle("Play & Stop", for: .normal)
        button.addTarget(self, action: #selector(playAndStop(_:)), for: .touchUpInside)
        button.sizeToFit()
        
        button.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        button.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        
        addSubview(button)
    }
    
    private lazy var _player: SMVideoPlayer = SMVideoPlayer()
    private lazy var _playerView: SMVideoPlayerView = SMVideoPlayerView(player: self._player)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }
}