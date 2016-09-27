//
//  SAPhotoAlbum.swift
//  SIMChat
//
//  Created by sagesse on 9/20/16.
//  Copyright © 2016 sagesse. All rights reserved.
//

import UIKit
import Photos


open class SAPhotoAlbum: NSObject {
    
    open static func reloadData() {
        
        _albums?.forEach {
            $0._photos = nil
        }
        _albums = nil
        _recentlyAlbum = nil
    }
    
    open func photos(with result: PHFetchResult<PHAsset>) -> [SAPhoto] {
        var photos: [SAPhoto] = []
        result.enumerateObjects({
            let photo = SAPhoto(asset: $0.0)
            photo.album = self
            photos.append(photo)
        })
        return photos
    }
    
    open var title: String? {
        return collection.localizedTitle
    }
    open var identifier: String {
        return collection.localIdentifier
    }
    
    open var type: PHAssetCollectionType {
        return collection.assetCollectionType
    }
    open var subtype: PHAssetCollectionSubtype {
        return collection.assetCollectionSubtype
    }
    
    open override var description: String {
        return collection.description
    }
    
    open var photos: [SAPhoto] {
        if let photos = _photos {
            return photos
        }
        let rs = PHAsset.fetchAssets(in: collection, options: nil)
        let photos = self.photos(with: rs)
        _photos = photos
        self.result = rs
        return photos
    }
    
    open static var albums: [SAPhotoAlbum] {
        if let albums = _albums {
            return albums
        }
        let albums = _fetchAssetCollections()
        _albums = albums
        return albums
    }
    open static var recentlyAlbum: SAPhotoAlbum? {
        if let album = _recentlyAlbum {
            return album
        }
        let album = _fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumRecentlyAdded).first
        _recentlyAlbum = album
        return album
    }
    
    open var collection: PHAssetCollection
    open var result: PHFetchResult<PHAsset>?
    
    fileprivate var _photos: [SAPhoto]?
    
    private static var _albums: [SAPhotoAlbum]?
    private static var _recentlyAlbum: SAPhotoAlbum??
    
    public init(collection: PHAssetCollection) {
        self.collection = collection
        super.init()
    }
}

// MARK: - Fetch

extension SAPhotoAlbum {
    
    fileprivate static func _fetchAssetCollections() -> [SAPhotoAlbum] {
        return [
            (.smartAlbum, .smartAlbumUserLibrary),
            (.album, .albumMyPhotoStream),
            
            (.smartAlbum, .smartAlbumRecentlyAdded),
            (.album, .albumSyncedAlbum),
            
            (.album, .albumRegular),
        ].reduce([]) {
            $0 + _fetchAssetCollections(with: $1.0, subtype: $1.1)
        }
    }
    fileprivate static func _fetchAssetCollections(with type: PHAssetCollectionType, subtype: PHAssetCollectionSubtype, options: PHFetchOptions? = nil) -> [SAPhotoAlbum] {
        var albums: [SAPhotoAlbum] = []
        PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: nil).enumerateObjects({ 
            albums.append(SAPhotoAlbum(collection: $0.0))
        })
        return albums
    }
}
