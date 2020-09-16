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
    
    private let searchController = UISearchController(searchResultsController: nil) //Создаем экземпляр класса SearchController с инициализатором в который передаем nil (в этот метод мы передаем информацию, на какой ViewController передавать найденные значения (nil - передача в текущий) и идем делать расширение для его работы
    private lazy var places = realm.objects(Place.self)
    private var filteredPlaces: Results<Place>! //создаем экземпляр класса нашей модели
    private var ascendingSorting = true //создаем свойство для хранения информации, в каком направлении проводить сортировку(реверс)
    private var searchBarIsEmpty: Bool { //создаем логическое свойство в зависимости от наличия текста в строке поиска
        guard let searchText = searchController.searchBar.text else {return false} // если текст = nil то возвращаем false
        return searchText.isEmpty //если текст есть или нажимался поиск, то возвращаем значение isEmpty
    }
    private var isFiltering: Bool { // создаем свойство которое возвращает true  если searchController активен и в нем есть текст
        return searchController.isActive && !searchBarIsEmpty
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl! //Outlet для считывания SegmentedControl
    @IBOutlet weak var reversedButton: UIBarButtonItem!//Outlet для считывания кнопки реверса
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDefaultPlace()

        //Создание SearchController на NavigationBar
        searchController.searchResultsUpdater = self //указываем где будут отображаться результаты поиска (пишем self - значит на текущем представлении)
        searchController.obscuresBackgroundDuringPresentation = false //По умолчанию результат поиска не позволяет взаимодействовать с элементами на экране, если отключаем параметр, то можем взаимодействовать как с основным -> указываем, что при поиске, основное содержимое не должно скрываться
        searchController.searchBar.placeholder = "Search" //указываем что будет отображаться в строке поиска
        navigationItem.searchController = searchController //присваиваем на NavigationBar наш SearchController
        definesPresentationContext = true //позволяет опустить строку поиска, при переходе на другой экран
        
        
        
    }

    // MARK: - Table view data source


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering{ // если мы ввели какойто поисковой запрос, то на экран выводим кол-во элементов из отфильтрованного массива, а не полностью
            return filteredPlaces.count
        }
        return places.isEmpty ? 0 : places.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PlacesCellController
        var place = Place() // создаем пустой объект нашей модели
        
        if isFiltering{ //если мы ввели какойто поисковой запрос, то на экран выводим элементы из отфильтрованного массива
            place = filteredPlaces[indexPath.row]
        } else { //если поисковой запрос пустой, то выводим полностью
            place = places[indexPath.row]
        }
        
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
            
            var place = Place() // создаем пустой объект нашей модели
            
            if isFiltering{ //если мы ввели какойто поисковой запрос, то на экран выводим элементы из отфильтрованного массива
                place = filteredPlaces[index]
            } else { //если поисковой запрос пустой, то выводим полностью
                place = places[index]
            }
            nvc.currentPlace = place //передаем на другой экран значение (в данном случае из массива places по индексу строки)
            
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

extension MainViewController: UISearchResultsUpdating{ //делаем расширение для работы с поисковой строкой + реализуем обязательный метод
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContetntForSearchText(searchController.searchBar.text!) // при вводе значений в поисковую строку, вызывается данный метод и получая значение из строки поиска, запускаем функцию для фильтрации
    }
    
    //создаем приватную функцию для непосредственной фильтрации нашего массива по поисковому запросу
    private func filterContetntForSearchText(_ searchText: String){ //передаем внутрь поисковой текст
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText) //искать будем по предикату (т.к. такая возможность есть в БД Realm)
        //name и location - наименование полей в БД(модели) по которым будем фильтровать
        //CONTAINS - содержит (синтаксис фильтрации по предикату)
        //[c] - означает, что мы не привязываем к регистру и ищем по лубым буквам
        //%@ - элемент куда подставим переменную для фильтрации
        //searchText - переменная которая заменит %@ и по ней будет происходить поиск
        tableView.reloadData()
    }
    
    
}
