//
//  PlacesCellController.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 11.08.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import UIKit

class PlacesCellController: UITableViewCell {
    
    @IBOutlet weak var imageOutlet: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
