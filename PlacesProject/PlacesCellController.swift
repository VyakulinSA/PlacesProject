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
    @IBOutlet weak var minRaitingControl: RaitingControl!{
        didSet{//наблюдатель. При любом изменении outlet в outlet отправляются изменения свойств, там в свою очередь срабатывет другой didSet
            minRaitingControl.update = false
            minRaitingControl.starsSize = CGSize(width: 22.0, height: 22.0)
        }
    }
    

}
