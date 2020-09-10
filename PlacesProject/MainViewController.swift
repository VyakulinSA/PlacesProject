//
//  MainViewController.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 11.08.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import RealmSwift
import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    lazy var places = realm.objects(Place.self)
    var ascendingSorting = true //создаем свойство для хранения информации, в каком направлении проводить сортировку(реверс)
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl! //Outlet для считывания SegmentedControl
    @IBOutlet weak var reversedButton: UIBarButtonItem!//Outlet для считывания кнопки реверса
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDefaultPlace()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//         self.navigationItem.leftBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return places.isEmpty ? 0 : places.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PlacesCellController
        let place = places[indexPath.row]
        cell.frame.size.height = 85
        
        cell.imageOutlet.image = UIImage(data: place.imageData!)
        cell.imageOutlet.layer.cornerRadius = cell.imageOutlet.frame.size.height / 2
        cell.imageOutlet.clipsToBounds = true
        cell.nameLabel.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    

    
//     Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            StorageManage.delObject(places[indexPath.row])
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

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
    
    @IBAction func sortSelection(_ sender: UISegmentedControl) { //создаем Action который выполняется при нажатии на segmentedControl
        sortingPlace() //вызываем функцию сортировки
    }
    
    @IBAction func reversedSorting(_ sender: Any) { //создаем Action который выполняется при нажатии на кнопку Реверса
        
        ascendingSorting.toggle() //изменяем направление реверса при каждом нажатии
        
        if ascendingSorting { //условия изменений реверса (меняем изображения)
            reversedButton.image = #imageLiteral(resourceName: "AZ")
        } else {
            reversedButton.image = #imageLiteral(resourceName: "ZA")
        }
        
        sortingPlace() //вызываем функцию сортировки
        
    }
    
    private func sortingPlace(){ //общая функция сортировки для SegmentedControl и Reversed
        if segmentedControl.selectedSegmentIndex == 0 { //Если выбран первый пункт SegmentedControl
            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting) //массив с элементами из базы сортируем по дате и с условием выбранного реверса
        } else {
            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting) // если другой элемент segmentedControl то по имени и в зависимости от значения реверса
        }
        
        tableView.reloadData() //делаем обновление таблицы после сортировки
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
