//
//  ImageCache.swift
//  GridImageProject
//
//  Created by dooth21 on 07/05/24.
//

import UIKit

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
    private init() {}
}
