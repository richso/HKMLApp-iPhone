//
//  SDToSKCache.swift
//  HKMLApp
//
//  Created by Richard So on 23/1/2018.
//  Copyright © 2018 Netrogen Creative. All rights reserved.
//

import SKPhotoBrowser
import SDWebImage

class SDToSKCache: SKImageCacheable {
    func removeAllImages() {
        cache.clearMemory()
    }
    

    var cache: SDImageCache
    
    required init() {
        cache = SDImageCache.shared
    }
    
    func imageForKey(_ key: String) -> UIImage? {
        return cache.imageFromCache(forKey: key)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.store(image, forKey: key, completion: nil)
    }
    
    func removeImageForKey(_ key: String) {
        cache.removeImage(forKey: key, withCompletion: nil)
    }
    
}
