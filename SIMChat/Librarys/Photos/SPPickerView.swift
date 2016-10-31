//
//  SPPickerView.swift
//  SIMChat
//
//  Created by sagesse on 9/21/16.
//  Copyright © 2016 sagesse. All rights reserved.
//

import UIKit
import Photos

@objc public protocol SPPickerViewDelegate: NSObjectProtocol {
   
    // check whether item can select
    @objc optional func recentlyView(_ recentlyView: SPPickerView, shouldSelectItemFor photo: SPAsset) -> Bool
    @objc optional func recentlyView(_ recentlyView: SPPickerView, didSelectItemFor photo: SPAsset)
    
    // check whether item can deselect
    @objc optional func recentlyView(_ recentlyView: SPPickerView, shouldDeselectItemFor photo: SPAsset) -> Bool
    @objc optional func recentlyView(_ recentlyView: SPPickerView, didDeselectItemFor photo: SPAsset)
    
    // data bytes lenght change
    @objc optional func recentlyView(_ recentlyView: SPPickerView, didChangeBytes bytes: Int)
    
    // tap item
    @objc optional func recentlyView(_ recentlyView: SPPickerView, tapItemFor photo: SPAsset, with sender: Any)
}

@objc public class SPPickerView: UIView {
    
    /// 是否允许编辑图片, 默认值为false
    public dynamic var allowsEditing: Bool = false
    /// 是否允许多选, 默认值为true
    public dynamic var allowsMultipleSelection: Bool = true {
        willSet {
            guard allowsMultipleSelection != newValue else {
                return
            }
            _contentView.visibleCells.forEach {
                ($0 as? SPPickerViewCell)?.photoView.allowsSelection = newValue
            }
        }
    }
    
    /// 是否使用原图, 默认值为false
    public dynamic var alwaysSelectOriginal: Bool = false {
        didSet {
            _updateBytesLenght()
        }
    }
    
    /// 选中的图片
    public dynamic var selectedPhotos: Array<SPAsset> {
        set {
            _selectedPhotos = newValue
            _selectedPhotoSets = Set(newValue)
            
            // 更新所有
            _contentView.visibleCells.forEach { 
                ($0 as? SPPickerViewCell)?.photoView.updateSelection()
            }
        }
        get {
            return _selectedPhotos
        }
    }
    
    ///
    /// 代理
    ///
    public weak var delegate: SPPickerViewDelegate?
    
    
    ///
    /// 显示指定的图片(如果存在的话)
    ///
    /// - parameter photo:    指定的图片
    /// - parameter animated: 是否需要动画
    ///
    public func scroll(to photo: SPAsset, animated: Bool) {
        guard let index = _photos?.index(of: photo) else {
            return
        }
        _logger.trace(index)
        
        _contentView.scrollToItem(at: IndexPath(item: index, section: 0),
                                  at: .centeredHorizontally,
                                  animated: animated)
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // 只有在将要显示的时候才去请示权限
        if !_isRequestedAuthorization {
            _isRequestedAuthorization = true
            
            SPLibrary.shared.requestAuthorization {
                self._updatePhotosForAuthorization($0)
            }
        }
    }
    
    
    fileprivate func _cachePhotos(_ photos: [SPAsset]) {
        // 缓存加速
        //        let options = PHImageRequestOptions()
        //        let scale = UIScreen.main.scale
        //        let size = CGSize(width: 120 * scale, height: 120 * scale)
        //        
        //        options.deliveryMode = .fastFormat
        //        options.resizeMode = .fast
        //        
        //        SPLibrary.shared.startCachingImages(for: photos, targetSize: size, contentMode: .aspectFill, options: options)
        //        //SPLibrary.shared.stopCachingImages(for: photos, targetSize: size, contentMode: .aspectFill, options: options)
    }
    
    private func _init() {
        
        _contentViewLayout.scrollDirection = .horizontal
        _contentViewLayout.minimumLineSpacing = 4
        _contentViewLayout.minimumInteritemSpacing = 4
        
        _contentView.frame = bounds
        _contentView.backgroundColor = .clear
        _contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _contentView.showsVerticalScrollIndicator = false
        _contentView.showsHorizontalScrollIndicator = false
        _contentView.scrollsToTop = false
        _contentView.allowsSelection = false
        _contentView.allowsMultipleSelection = false
        _contentView.alwaysBounceHorizontal = true
        _contentView.register(SPPickerViewCell.self, forCellWithReuseIdentifier: "Item")
        _contentView.contentInset = UIEdgeInsetsMake(0, 4, 0, 4)
        _contentView.dataSource = self
        _contentView.delegate = self
        
        addSubview(_contentView)
        
        SPLibrary.shared.register(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectItem(_:)), name: .SPSelectionableDidSelectItem, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDeselectItem(_:)), name: .SPSelectionableDidDeselectItem, object: nil)
    }
    
    fileprivate var _status: SPhotoStatus = .notError
    
    fileprivate var _album: SPAlbum?
    
    
    fileprivate var _photos: [SPAsset]?
    fileprivate var _photosResult: PHFetchResult<PHAsset>?
    
    fileprivate var _isRequestedAuthorization: Bool = false
    
    fileprivate lazy var _selectedPhotos: Array<SPAsset> = []
    fileprivate lazy var _selectedPhotoSets: Set<SPAsset> = []
    
    fileprivate lazy var _tipsLabel: UILabel = UILabel()
    
    fileprivate lazy var _contentViewLayout: SPPickerViewLayout = SPPickerViewLayout()
    fileprivate lazy var _contentView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: self._contentViewLayout)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }
    deinit {
        logger.trace()
        
        SPLibrary.shared.unregisterChangeObserver(self)
    }
}

// MARK: - Events

private extension SPPickerView {
    
    dynamic func selectItem(_ photo: SPAsset) {
        _logger.trace()
        
        if !_selectedPhotoSets.contains(photo) {
            _selectedPhotoSets.insert(photo)
            _selectedPhotos.append(photo)
        }
        delegate?.recentlyView?(self, didSelectItemFor: photo)
    }
    dynamic func deselectItem(_ photo: SPAsset) {
        _logger.trace()
        
        if let index = _selectedPhotos.index(of: photo) {
            _selectedPhotoSets.remove(photo)
            _selectedPhotos.remove(at: index)
        }
        delegate?.recentlyView?(self, didDeselectItemFor: photo)
    }
    
    dynamic func didSelectItem(_ sender: Notification?) {
        guard let photo = sender?.object as? SPAsset else {
            return
        }
        _logger.trace()
        _contentView.visibleCells.forEach {
            let cell = $0 as? SPPickerViewCell
            guard cell?.photoView.photo == photo && !(cell?.photoView.isSelected ?? false) else {
                return
            }
            cell?.photoView.updateSelection()
        }
    }
    dynamic func didDeselectItem(_ sender: Notification?) {
        
        _logger.trace()
        _contentView.visibleCells.forEach {
            let cell = $0 as? SPPickerViewCell
            guard cell?.photoView.isSelected ?? false else {
                return
            }
            cell?.photoView.updateSelection()
        }
    }
}

fileprivate extension SPPickerView {
    
    func _updateStatus(_ newValue: SPhotoStatus) {
        //_logger.trace(newValue)
        
        _status = newValue
        
        switch newValue {
        case .notError:
            
            _tipsLabel.isHidden = true
            _contentView.isHidden = false
            
            _tipsLabel.removeFromSuperview()
            
        case .notData:
            _tipsLabel.isHidden = false
            
            _tipsLabel.text = "暂无图片"
            _tipsLabel.textAlignment = .center
            _tipsLabel.textColor = .lightGray
            _tipsLabel.font = UIFont.systemFont(ofSize: 20)
            _tipsLabel.frame = bounds
            _tipsLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            _contentView.isHidden = true
            _contentView.reloadData()
            
            addSubview(_tipsLabel)
            
        case .notPermission:
            
            _tipsLabel.isHidden = false
            
            _tipsLabel.text = "照片被禁用, 请在设置-隐私中开启"
            _tipsLabel.textAlignment = .center
            _tipsLabel.textColor = .lightGray
            _tipsLabel.font = UIFont.systemFont(ofSize: 15)
            _tipsLabel.frame = bounds
            _tipsLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            _contentView.isHidden = true
            _contentView.reloadData()
            
            addSubview(_tipsLabel)
        }
    }
    
    func _updatePhotosForAuthorization(_ hasPermission: Bool) {
        _logger.trace(hasPermission)
        
        // 检查访问权限
        guard hasPermission else {
            _updateStatus(.notPermission)
            return
        }
        // 读取最近添中的图集
        if let album = SPAlbum.recentlyAlbum, let newResult = album.fetchResult {
            _album = album
            _photos = album.photos(with: newResult).reversed()
            _photosResult = newResult
        }
        // 检查相册中有没有图片
        guard let photos = _photos, !photos.isEmpty else {
            _contentView.reloadData()
            _updateStatus(.notData)
            return
        }
        // 更新UI
        _cachePhotos(photos)
        _contentView.reloadData()
        
        _updateStatus(.notError)
    }
    func _updatePhotosForChange(_ newResult: PHFetchResult<PHAsset>, _ inserts: [IndexPath], _ changes: [IndexPath], _ removes: [IndexPath]) {
        _logger.trace("inserts: \(inserts), changes: \(changes), removes: \(removes)")
        
        // 更新数据
        _photos = _album?.photos(with: newResult).reversed()
        _photosResult = newResult
        
        // 检查相册中有没有图片
        guard let photos = _photos, !photos.isEmpty else {
            _contentView.reloadData()
            _updateStatus(.notData)
            return
        }
        // 更新UI
        if !(inserts.isEmpty && changes.isEmpty && removes.isEmpty) {
            _contentView.performBatchUpdates({ [_contentView] in
                
                _contentView.reloadItems(at: changes)
                _contentView.deleteItems(at: removes)
                _contentView.insertItems(at: inserts)
                
            }, completion: nil)
        }

        _cachePhotos(photos)
        _updateStatus(.notError)
    }
    
    func _updateBytesLenght() {
        _logger.trace()
        
        guard alwaysSelectOriginal else {
            _updateBytesLenght(with: 0)
            return
        }
        
        var count: Int = 0
        let group: DispatchGroup = DispatchGroup()
        
        selectedPhotos.forEach { photo in
            group.enter()
            photo.data(with: { data in
                if let data = data, count != -1 {
                    count += data.count
                } else {
                    count = -1 // 存在-1表明有图片在iclund上面
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) { [weak self] in
            self?._updateBytesLenght(with: count)
        }
    }
    func _updateBytesLenght(with lenght: Int) {
        _logger.trace(lenght)
        
        delegate?.recentlyView?(self, didChangeBytes: lenght)
    }
    
    func _updateSelectionForRemove(_ photo: SPAsset) {
        // 检查这个图片有没有被删除
        guard !SPLibrary.shared.isExists(of: photo) else {
            return
        }
        _logger.trace(photo.identifier)
        // 需要强制删除?
        if selection(self, shouldDeselectItemFor: photo) {
            selection(self, didDeselectItemFor: photo)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension SPPickerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        _contentView.visibleCells.forEach {
            ($0 as? SPPickerViewCell)?.photoView.updateEdge()
        }
    }
   
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _photos?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Item", for: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? SPPickerViewCell else {
            return
        }
        guard let photo = _photos?[indexPath.item] else {
            cell.isSelected = false
            cell.photoView.delegate = nil
            cell.photoView.photo = nil
            return 
        }
        cell.photoView.allowsSelection = allowsMultipleSelection
        cell.photoView.delegate = self
        cell.photoView.photo = photo
        cell.photoView.updateEdge()
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let photo = _photos?[indexPath.item] else {
            return .zero
        }
        let pwidth = Double(photo.pixelWidth)
        let pheight = Double(photo.pixelHeight)
        let height = collectionView.frame.height
        let scale = Double(height) / pheight
        
        return CGSize(width: CGFloat(pwidth * scale), height: height)
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension SPPickerView: PHPhotoLibraryChangeObserver {
    
    // 图片发生改变
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self._photoLibraryDidChangeOnMainThread(changeInstance)
        }
    }
    
    private func _photoLibraryDidChangeOnMainThread(_ changeInstance: PHChange) {
        // 检查选中的图片有没有被删除
        _selectedPhotos.forEach {
            _updateSelectionForRemove($0)
        }
        // 全部更新, 防止有选中图片删除/更新
        _updateBytesLenght()
        // 检查有没有发生改变
        guard let result = self._photosResult, let change = changeInstance.changeDetails(for: result), change.hasIncrementalChanges else {
            return
        }
        let inserts = change.insertedIndexes?.map { idx -> IndexPath in
            // ... 这可能会产生bug
            return IndexPath(item: 0, section: 0)
            } ?? []
        let changes = change.changedObjects.flatMap { asset -> IndexPath? in
            if let idx = _photos?.index(where: { $0.asset.localIdentifier == asset.localIdentifier }) {
                return IndexPath(item: idx, section: 0)
            }
            return nil
        }
        let removes = change.removedObjects.flatMap { asset -> IndexPath? in
            if let idx = _photos?.index(where: { $0.asset.localIdentifier == asset.localIdentifier }) {
                return IndexPath(item: idx, section: 0)
            }
            return nil
        }
        
        _album?.clearCache()
        _photosResult = change.fetchResultAfterChanges
        _updatePhotosForChange(change.fetchResultAfterChanges, inserts, changes, removes)
    }
}

// MARK: - SPAssetViewDelegate(Forwarding)

extension SPPickerView: SPSelectionable {
    
    
    /// gets the index of the selected item, if item does not select to return NSNotFound
    public func selection(_ selection: Any, indexOfSelectedItemsFor photo: SPAsset) -> Int {
        return _selectedPhotos.index(of: photo) ?? NSNotFound
    }
   
    // check whether item can select
    public func selection(_ selection: Any, shouldSelectItemFor photo: SPAsset) -> Bool {
        return delegate?.recentlyView?(self, shouldSelectItemFor: photo) ?? true
    }
    public func selection(_ selection: Any, didSelectItemFor photo: SPAsset) {
        //_logger.trace()
        
        scroll(to: photo, animated: true)
        selectItem(photo)
        
        // 通知UI更新
        NotificationCenter.default.post(name: .SPSelectionableDidSelectItem, object: photo)
    }
    
    // check whether item can deselect
    public func selection(_ selection: Any, shouldDeselectItemFor photo: SPAsset) -> Bool {
        return delegate?.recentlyView?(self, shouldDeselectItemFor: photo) ?? true
    }
    public func selection(_ selection: Any, didDeselectItemFor photo: SPAsset) {
        //_logger.trace()
        
        deselectItem(photo)
        // 通知UI更新
        NotificationCenter.default.post(name: .SPSelectionableDidDeselectItem, object: photo)
    }
    
    // editing
    func selection(_ selection: Any, willEditing sender: Any) {
        _logger.trace()
        
        // 清除0, 然后重新计算
        _updateBytesLenght(with: 0)
    }
    func selection(_ selection: Any, didEditing sender: Any) {
        _logger.trace()
        
        _updateBytesLenght()
    }
    
    // tap item
    public func selection(_ selection: Any, tapItemFor photo: SPAsset, with sender: Any) {
        _logger.trace()
        
        delegate?.recentlyView?(self, tapItemFor: photo, with: selection)
    }
}