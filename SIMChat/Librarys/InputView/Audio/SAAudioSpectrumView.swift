//
//  SAAudioSpectrumView.swift
//  SIMChat
//
//  Created by sagesse on 9/16/16.
//  Copyright © 2016 sagesse. All rights reserved.
//

import UIKit

@objc
public protocol SAAudioSpectrumViewDataSource: NSObjectProtocol {
    
    func spectrumView(_ spectrumView: SAAudioSpectrumView, peakPowerFor channel: Int) -> Float
    func spectrumView(_ spectrumView: SAAudioSpectrumView, averagePowerFor channel: Int) -> Float
    
    @objc optional func spectrumView(willUpdateMeters spectrumView: SAAudioSpectrumView)
    @objc optional func spectrumView(didUpdateMeters spectrumView: SAAudioSpectrumView)
}

open class SAAudioSpectrumView: UIView {
    
    open weak var dataSource: SAAudioSpectrumViewDataSource?
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: 120, height: 24)
    }
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        guard newWindow == nil else {
            return
        }
        stopAnimating()
    }
    
    open var color: UIColor? {
        willSet { 
            _leftLayers.forEach { 
                $0.backgroundColor = newValue?.cgColor
            }
            _rightLayers.forEach {
                $0.backgroundColor = newValue?.cgColor
            }
        }
    }
    
    open var isAnimating: Bool {
        return false
    }
    open func startAnimating() {
        guard _link == nil else {
            return
        }
            
        _logger.trace()
        
        _link = CADisplayLink(target: self, selector: #selector(tack(_:)))
        _link?.frameInterval = 4
        _link?.add(to: .main, forMode: .commonModes)
    }
    open func stopAnimating() {
        guard _link != nil else {
            return
        }
        _logger.trace()
        
        _link?.remove(from: .main, forMode: .commonModes)
        _link = nil
    }
    
    @objc func tack(_ sender: AnyObject) {
        
        dataSource?.spectrumView?(willUpdateMeters: self)
        
        // 读取波形
        let wl = Double(dataSource?.spectrumView(self, averagePowerFor: 0) ?? -160)
        let wr = Double(dataSource?.spectrumView(self, averagePowerFor: 1) ?? -160)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // 小于-40一律视为静音
        let sl = CGFloat(_decibelsToLevel(wl))
        let sr = CGFloat(_decibelsToLevel(wr))
        
        var pbl = CGRect(x: 0, y: 0, width: 2, height: 2 + round(sl * 8) * 2)
        var pbr = CGRect(x: 0, y: 0, width: 2, height: 2 + round(sr * 8) * 2)
        
        _leftLayers.forEach {
            swap(&$0.bounds, &pbl)
        }
        _rightLayers.forEach {
            swap(&$0.bounds, &pbr)
        }
        
        CATransaction.commit()
        
        dataSource?.spectrumView?(didUpdateMeters: self)
    }
    
    @inline(__always)
    private func _decibelsToLevel(_ decibels: Double) -> Double {
        // Link: http://stackoverflow.com/questions/9247255/am-i-doing-the-right-thing-to-convert-decibel-from-120-0-to-0-120/16192481#16192481
        
        var level = 0.0 // The linear 0.0 .. 1.0 value we need.
        let minDecibels = -70.0 // Or use -60dB, which I measured in a silent room.
        
        if decibels < minDecibels {
            level = 0.0
        } else if decibels >= 0.0 {
            level = 1.0
        } else {
            let root = 2.0
            let minAmp = pow(10, 0.05 * minDecibels)
            let inverseAmpRang = 1 / (1 - minAmp)
            let amp = pow(10, 0.05 * decibels)
            let adjAmp = (amp - minAmp) * inverseAmpRang
            
            level = pow(adjAmp, 1 / root)
        }
        return level
    }
    
    private func _init() {
        
        let x = intrinsicContentSize.width / 2
        let y = intrinsicContentSize.height / 2
        let sw = CGFloat(28)
        
        for i in 0 ..< 10 {
            let l = CALayer()
            let r = CALayer()
            
            l.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            r.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            l.position = CGPoint(x: (x - CGFloat(i * (2 + 2)) - sw), y: y)
            r.position = CGPoint(x: (x + CGFloat(i * (2 + 2)) + sw), y: y)
            l.bounds = CGRect(x: 0, y: 0, width: 2, height: 3)
            r.bounds = CGRect(x: 0, y: 0, width: 2, height: 3)
            
            _leftLayers.append(l)
            _rightLayers.append(r)
            
            layer.addSublayer(l)
            layer.addSublayer(r)
        }
        
        color = UIColor(colorLiteralRed: 0xfb / 255.0, green: 0x7a / 255.0, blue: 0x0d / 255.0, alpha: 1.0)
    }
    
    private var _link: CADisplayLink?
    
    private lazy var _leftLayers = [CALayer]()
    private lazy var _rightLayers = [CALayer]()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }
}

