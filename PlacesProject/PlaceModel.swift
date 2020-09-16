//
//  PlaceModel.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 14.08.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import UIKit
import RealmSwift

class Place: Object {
    @objc dynamic var name = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?
    @objc dynamic var date = Date()
    
    convenience init(name: String, location: String?, type: String?, imageData: Data?){
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        
    }
    
    let restaurantNames = [
        "Burger Heroes", "Kitchen", "Bonsai", "Дастархан",
        "Индокитай", "X.O", "Балкан Гриль", "Sherlock Holmes",
        "Speak Easy", "Morris Pub", "Вкусные истории",
        "Классик", "Love&Life", "Шок", "Бочка"]

    func defaultPlaces(){
        for name in restaurantNames {
            let image = UIImage(named: name)
            guard let imageData = image?.pngData() else {return}
            let newPlace = Place(name: name, location: "Samara", type: "Bar", imageData: imageData)
            
            StorageManage.saveObject(newPlace)
            
            
        }
    }
    
}

    





