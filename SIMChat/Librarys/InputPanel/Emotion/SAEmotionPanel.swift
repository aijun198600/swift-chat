//
//  SAEmotionPanel.swift
//  SIMChat
//
//  Created by sagesse on 9/6/16.
//  Copyright © 2016 sagesse. All rights reserved.
//

import UIKit
import CoreGraphics

// ## TODO
// [ ] * - Version 2, 参考系统Emoji键盘
// [ ] * - 横屏支持
// [x] SAEmotionPanel - 小表情支持
// [x] SAEmotionPanel - 大表情支持
// [x] SAEmotionPanel - 自定义大小/间距/缩进
// [ ] SAEmotionPanel - 动态图片支持
// [x] SAEmotionPanel - Tabbar支持
// [x] SAEmotionPanel - 更新page
// [ ] SAEmotionPanel - 长按删除
// [ ] SAEmotionPanel - 发送/设置按钮
// [ ] SAEmotion - UIView支持
// [x] SAEmotion - UIImage支持
// [x] SAEmotion - NSString/NSAttributedString支持
// [x] SAEmotionPage - Add支持
// [x] SAEmotionPage - 删除按钮
// [x] SAEmotionPage - 异步绘制
// [x] SAEmotionTabItemView - 选中
// [x] SAEmotionTabItemView - 选中高亮
// [x] SAEmotionPageView - 选中
// [x] SAEmotionPageView - 选中高亮
// [x] SAEmotionPageView - 长按预览
// [ ] SAEmotionPageView - 横屏支持


@objc public protocol SAEmotionPanelDataSource: NSObjectProtocol {
    
    func numberOfGroups(in emotion: SAEmotionPanel) -> Int
    func emotion(_ emotion: SAEmotionPanel, groupAt index: Int) -> SAEmotionGroup
    
    @objc optional func emotion(_ emotion: SAEmotionPanel, moreViewForGroupAt index: Int) -> UIView?
}
@objc public protocol SAEmotionPanelDelegate: NSObjectProtocol {
    
    @objc optional func emotion(_ emotion: SAEmotionPanel, shouldSelectFor item: SAEmotion) -> Bool
    @objc optional func emotion(_ emotion: SAEmotionPanel, didSelectFor item: SAEmotion)
    
    @objc optional func emotion(_ emotion: SAEmotionPanel, shouldPreviewFor item: SAEmotion?) -> Bool
    @objc optional func emotion(_ emotion: SAEmotionPanel, didPreviewFor item: SAEmotion?)
    
}

@objc open class SAEmotionPanel: UIView {
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: 253)
    }
   
    open weak var dataSource: SAEmotionPanelDataSource?
    open weak var delegate: SAEmotionPanelDelegate?
    
    // MARK: Private Method
    
    private func _init() {
        //_logger.trace()
        
        _color = UIColor(colorLiteralRed: 0xec / 0xff, green: 0xed / 0xff, blue: 0xf1 / 0xff, alpha: 1)
        
        _pageControl.numberOfPages = 8
        _pageControl.hidesForSinglePage = true
        _pageControl.pageIndicatorTintColor = UIColor.gray
        _pageControl.currentPageIndicatorTintColor = UIColor.darkGray
        _pageControl.translatesAutoresizingMaskIntoConstraints = false
        _pageControl.backgroundColor = .clear
        _pageControl.isUserInteractionEnabled = false
        //_pageControl.addTarget(self, action: #selector(onPageChanged(_:)), for: .valueChanged)
        
        _contentViewLayout.scrollDirection = .horizontal
        _contentViewLayout.minimumLineSpacing = 0
        _contentViewLayout.minimumInteritemSpacing = 0
        
        _contentView.delegate = self
        _contentView.dataSource = self
        _contentView.scrollsToTop = false
        _contentView.isPagingEnabled = true
        _contentView.delaysContentTouches = false
        _contentView.showsVerticalScrollIndicator = false
        _contentView.showsHorizontalScrollIndicator = false
        _contentView.register(SAEmotionPageView.self, forCellWithReuseIdentifier: "Page")
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.backgroundColor = .clear
        
        _previewer.isHidden = true
        _previewer.isUserInteractionEnabled = false
        
        _tabbarLayout.scrollDirection = .horizontal
        _tabbarLayout.minimumLineSpacing = 0
        _tabbarLayout.minimumInteritemSpacing = 0
        
        _tabbar.register(SAEmotionTabItemView.self, forCellWithReuseIdentifier: "Page")
        _tabbar.translatesAutoresizingMaskIntoConstraints = false
        _tabbar.dataSource = self
        _tabbar.backgroundColor = .white
        _tabbar.contentInset = UIEdgeInsetsMake(0, 0, 0, 45)
        _tabbar.delegate = self
        _tabbar.scrollsToTop = false
        _tabbar.showsVerticalScrollIndicator = false
        _tabbar.showsHorizontalScrollIndicator = false
        _tabbar.alwaysBounceHorizontal = true
        
        backgroundColor = _color
        
        // add views
        
        addSubview(_contentView)
        addSubview(_tabbar)
        addSubview(_pageControl)
        addSubview(_previewer)
        
        // add constraints
       
        addConstraint(_SALayoutConstraintMake(_contentView, .top, .equal, self, .top))
        addConstraint(_SALayoutConstraintMake(_contentView, .left, .equal, self, .left))
        addConstraint(_SALayoutConstraintMake(_contentView, .right, .equal, self, .right))
        
        addConstraint(_SALayoutConstraintMake(_pageControl, .left, .equal, self, .left))
        addConstraint(_SALayoutConstraintMake(_pageControl, .right, .equal, self, .right))
        addConstraint(_SALayoutConstraintMake(_pageControl, .bottom, .equal, _contentView, .bottom, -10))
        
        addConstraint(_SALayoutConstraintMake(_tabbar, .top, .equal, _contentView, .bottom))
        addConstraint(_SALayoutConstraintMake(_tabbar, .left, .equal, self, .left))
        addConstraint(_SALayoutConstraintMake(_tabbar, .right, .equal, self, .right))
        addConstraint(_SALayoutConstraintMake(_tabbar, .bottom, .equal, self, .bottom))
        
        addConstraint(_SALayoutConstraintMake(_tabbar, .height, .equal, nil, .notAnAttribute, 37))
        addConstraint(_SALayoutConstraintMake(_pageControl, .height, .equal, nil, .notAnAttribute, 20))
    }
    
    fileprivate var _color: UIColor?
    fileprivate var _currentGroup: Int?
    fileprivate var _contentViewIsInit: Bool = false
    
    fileprivate lazy var _tabbarLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    fileprivate lazy var _tabbar: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: self._tabbarLayout)
    
    fileprivate lazy var _previewer: SAEmotionPreviewer = SAEmotionPreviewer()
    fileprivate lazy var _pageControl: UIPageControl = UIPageControl()
    
    fileprivate lazy var _contentViewLayout: SAEmotionPanelLayout = SAEmotionPanelLayout()
    fileprivate lazy var _contentView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: self._contentViewLayout)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }
}

// MARK: - SAEmotionDelegate(Forwarding)

extension SAEmotionPanel: SAEmotionDelegate {
    
    open func emotion(shouldSelectFor emotion: SAEmotion) -> Bool {
        return delegate?.emotion?(self, shouldSelectFor: emotion) ?? true
    }
    open func emotion(shouldPreviewFor emotion: SAEmotion?) -> Bool {
        return delegate?.emotion?(self, shouldPreviewFor: emotion) ?? true
    }
    
    open func emotion(didSelectFor emotion: SAEmotion) {
        delegate?.emotion?(self, didSelectFor: emotion) 
    }
    open func emotion(didPreviewFor emotion: SAEmotion?) {
        delegate?.emotion?(self, didPreviewFor: emotion) 
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension SAEmotionPanel: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView === _tabbar {
            return
        }
        if scrollView === _contentView {
            guard let idx = _contentView.indexPathForItem(at: targetContentOffset.move()) else {
                return
            }
            _updateMoreView(at: idx)
            _updatePageNumber(at: idx)
        }
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView === _tabbar {
            return 1
        }
        if collectionView === _contentView {
            return dataSource?.numberOfGroups(in: self) ?? 0
        }
        return 0
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === _tabbar {
            return dataSource?.numberOfGroups(in: self) ?? 0
        }
        if collectionView === _contentView {
            guard let ds = dataSource else {
                return 0
            }
            let pageCount = _contentViewLayout.numberOfPages(in: section) {
                ds.emotion(self, groupAt: section)
            }
            if !_contentViewIsInit {
                _contentViewIsInit = true
                let idx = IndexPath(item: 0, section: 0)
                _updateMoreView(at: idx)
                _updatePageNumber(at: idx)
            }
            return pageCount
        }
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Page", for: indexPath)
    }
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? SAEmotionPageView {
            cell.page = _contentViewLayout.page(at: indexPath)
            cell.delegate = self
            cell.previewer = _previewer
            return
        } 
        if let cell = cell as? SAEmotionTabItemView {
            cell.group = dataSource?.emotion(self, groupAt: indexPath.item)
            cell.selectedBackgroundView?.backgroundColor = _color
            return
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === _tabbar {
            let nidx = IndexPath(item: 0, section: indexPath.item)
            guard _contentView.indexPathsForVisibleItems.first?.section != nidx.section else {
                return // no change
            }
            _contentView.scrollToItem(at: nidx, at: .left, animated: false)
            _updateMoreView(at: nidx)
            _updatePageNumber(at: nidx)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === _tabbar {
            return CGSize(width: 45, height: collectionView.frame.height)
        }
        if collectionView === _contentView {
            return collectionView.frame.size
        }
        return .zero
    }
    
    private func _updateMoreView(at indexPath: IndexPath) {
        guard _currentGroup != indexPath.section else {
            return
        }
        let view = dataSource?.emotion?(self, moreViewForGroupAt: indexPath.section)
        
        _logger.trace(view)
        
        _currentGroup = indexPath.section
    }
    
    private func _updatePageNumber(at indexPath: IndexPath) {
        
        _pageControl.numberOfPages = _contentView.numberOfItems(inSection: indexPath.section)
        _pageControl.currentPage = indexPath.item
        
        let nidx = IndexPath(item: indexPath.section, section: 0)
        guard _tabbar.indexPathsForSelectedItems?.first?.item != nidx.item else {
            return
        }
        _tabbar.selectItem(at: nidx, animated: true, scrollPosition: .centeredHorizontally)
    }
}

