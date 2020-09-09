//
//  MainViewController.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 11.08.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import RealmSwift
import UIKit

class MainViewController: UITableViewController {
    
    lazy var places = realm.objects(Place.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDefaultPlace()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         self.navigationItem.leftBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return places.isEmpty ? 0 : places.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PlacesCellController
        let place = places[indexPath.row]
        
        cell.imageOutlet.image = UIImage(data: place.imageData!)
        cell.imageOutlet.layer.cornerRadius = cell.imageOutlet.frame.size.height / 2
        cell.imageOutlet.clipsToBounds = true
        cell.nameLabel.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    

    
//     Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            StorageManage.delObject(places[indexPath.row])
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" { //смотрим куда идет переход
            let nvc = segue.destination as! NewPlaceController //кастим до нужного контроллера
            guard let index = tableView.indexPathForSelectedRow?.row else {return} //получаем индекс выбранной строки для редаетирования
            nvc.currentPlace = places[index] //передаем на другой экран значение (в данном случае из массива places по индексу строки)
            
        }
    }
    

    @IBAction func unwindSegue(segue: UIStoryboardSegue){
        if segue.identifier == "Save"{
            guard let svc = segue.source as? NewPlaceController else {return}
            
            svc.savePlace()
//            places.append(svc.newPlace!)
            tableView.reloadData()
        }
    }
}

extension MainViewController {
    
    func loadDefaultPlace(){
        let defPlaces = Place()
        guard places.isEmpty else {return}
            defPlaces.defaultPlaces()
            StorageManage.saveObject(defPlaces)
    }
}
