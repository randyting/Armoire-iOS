//
//  AMRInventoryVenueCollectionViewCell.swift
//  ArmoireApp
//
//  Created by Morgan Wildermuth on 11/14/15.
//  Copyright © 2015 Armoire. All rights reserved.
//

import UIKit

class AMRInventoryVenueCollectionViewCell: UICollectionViewCell {

  @IBOutlet weak var imageView: UIImageView!

  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

  var category: AMRInventoryCategory! {
    didSet{
      if let checkedUrl = NSURL(string: category.imageUrl!) {
        imageView.contentMode = .ScaleAspectFit
        setImageValue(checkedUrl)
      }
    }
  }

  override func prepareForReuse() {
    self.imageView.image = nil;
  }

  func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
    NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
      completion(data: data, response: response, error: error)
      }.resume()
  }

  func setImageValue(url: NSURL){
    getDataFromUrl(url) { (data, response, error)  in
      dispatch_async(dispatch_get_main_queue()) { () -> Void in
        guard let data = data where error == nil else { return }
        self.imageView.image = UIImage(data: data)
      }
    }
  }

}
