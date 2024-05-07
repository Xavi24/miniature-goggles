//
//  ViewController.swift
//  GridImageProject
//
//  Created by Xavier on 06/05/24.
//

import UIKit

class GridCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var gridImageModel = [GridImageModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "GridCollectionViewCell", bundle: Bundle.main), forCellWithReuseIdentifier: "GridCell")
        let url = URL(string: "https://acharyaprashant.org/api/v2/content/misc/media-coverages?limit=100")!
        fetchData(from: url) { result in
            switch result {
            case .success(let data):
                self.gridImageModel = data
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                print("success \(data)")
            case .failure(let error):
                print("error \(error)")
            }
        }
    }
    
    func fetchData(from url: URL, completion: @escaping (Result<[GridImageModel], Error>) -> Void) {
        // Create a URLSession
        let session = URLSession.shared
        
        // Create a data task to fetch the data
        let task = session.dataTask(with: url) { (data, response, error) in
            // Handle errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Ensure there is data
            guard let jsonData = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            
            do {
                // Parse the JSON data using JSONDecoder
                let decodedData = try JSONDecoder().decode([GridImageModel].self, from: jsonData)
                completion(.success(decodedData))
            } catch {
                // Handle decoding errors
                completion(.failure(error))
            }
        }
        
        // Start the data task
        task.resume()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.gridImageModel.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCell", for: indexPath) as! GridCollectionViewCell
        if let thumbnail = gridImageModel[indexPath.row].thumbnail, let domain = thumbnail.domain, let basePath = thumbnail.basePath, let key = thumbnail.key {
            let imageUrl = domain + "/" + basePath + "/0/" + key
            if let url = URL(string: imageUrl) {
                let paddingSpace: CGFloat = 10 * 4 + 35
                let availableWidth = collectionView.bounds.width - paddingSpace
                let widthPerItem = availableWidth/3
                cell.loadImage(from: url, sizeOfItem: widthPerItem)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace: CGFloat = 10 * 4 + 35
        let availableWidth = collectionView.bounds.width - paddingSpace
        let widthPerItem = availableWidth/3
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 10
        }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
}

