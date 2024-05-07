//
//  GridCollectionViewCell.swift
//  GridImageProject
//
//  Created by Xavier on 06/05/24.
//

import UIKit

class GridCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageContentView: UIView!
    @IBOutlet weak var gridImageView: UIImageView!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageContentView.translatesAutoresizingMaskIntoConstraints = false
        imageContentView.layer.shadowColor = UIColor.black.cgColor // Shadow color
        imageContentView.layer.shadowOpacity = 0.5 // Shadow opacity
        imageContentView.layer.shadowOffset = CGSize(width: 0, height: 2) // Shadow offset
        imageContentView.layer.shadowRadius = 4 // Shadow radius
    }
    
    func loadImage(from url: URL, sizeOfItem: CGFloat) {
        gridImageView.image = UIImage(named: "placeholderImage")
        imageWidthConstraint.constant = sizeOfItem
        imageHeightConstraint.constant = sizeOfItem
        if let cachedImage = ImageCache.shared.object(forKey: url.absoluteString as NSString) {
            DispatchQueue.main.async {
                self.gridImageView.image = cachedImage
            }
            return
        }
        
        if let cachedImage = loadImageFromDisk(with: url.absoluteString) {
            ImageCache.shared.setObject(cachedImage, forKey: url.absoluteString as NSString)
            DispatchQueue.main.async {
                self.gridImageView.image = cachedImage
            }
            // Cache the image in memory for future use
            ImageCache.shared.setObject(cachedImage, forKey: url.absoluteString as NSString)
            return
        }
        DispatchQueue.global(qos: .background).async {
            let session = URLSession.shared
            let task = session.dataTask(with: url) { [weak self] (data, response, error) in
                
                guard let data = data, error == nil else { return }
                
                if let image = UIImage(data: data) {
                    
                    guard let croppedImage = image.cropped(to: CGSize(width: sizeOfItem, height: sizeOfItem)) else { return }
                    
                    ImageCache.shared.setObject(croppedImage, forKey: url.absoluteString as NSString)
                    
                    self?.saveImageToDisk(croppedImage, with: url.absoluteString)
                    
                    DispatchQueue.main.async {
                        self?.gridImageView.image = croppedImage
                        self?.gridImageView.contentMode = .scaleAspectFill
                        self?.gridImageView.clipsToBounds = true
                    }
                }
                else {
                    self?.gridImageView.image = UIImage(named: "placeholderImage")
                }
            }
            task.resume()
        }
        
    }
    
    private func saveImageToDisk(_ image: UIImage, with key: String) {
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        let filename = getDocumentsDirectory().appendingPathComponent(key)
        try? data.write(to: filename)
    }
        
    private func loadImageFromDisk(with key: String) -> UIImage? {
        let filename = getDocumentsDirectory().appendingPathComponent(key)
        guard let imageData = try? Data(contentsOf: filename) else { return nil }
        return UIImage(contentsOfFile: filename.path)
    }
        
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func prepareForReuse() {
        self.gridImageView.image = UIImage()
    }
}


extension UIImage {
    func cropped(to targetSize: CGSize) -> UIImage? {
        let imageSize = self.size
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let scaleFactor = max(widthRatio, heightRatio)
        
        let scaledWidth = imageSize.width * scaleFactor
        let scaledHeight = imageSize.height * scaleFactor
        
        let x = (targetSize.width - scaledWidth) / 2.0
        let y = (targetSize.height - scaledHeight) / 2.0
        
        let rect = CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage else { return nil }
        context.translateBy(x: 0, y: targetSize.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(cgImage, in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
