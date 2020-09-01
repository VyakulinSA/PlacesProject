//
//  StorageManager.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 01.09.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import RealmSwift

let realm = try! Realm()

class StorageManage{
    static func saveObject(_ place: Place) {
        try! realm.write {
            realm.add(place)
        }
    }
}
