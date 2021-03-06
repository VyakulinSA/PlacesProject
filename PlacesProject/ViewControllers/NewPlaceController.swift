//
//  NewPlaceController.swift
//  PlacesProject
///Users/vyakulinsa/Desktop/XCode/PlacesProject/PlacesProject/NewPlaceController.swift
//  Created by Вякулин Сергей on 16.08.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import UIKit

class NewPlaceController: UITableViewController {

    var currentPlace: Place? //создаем переменную для передачи значений на этот контроллер при редактировании
    
    @IBOutlet weak var newPlaceImage: UIImageView!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var locationTF: UITextField!
    @IBOutlet weak var typeTF: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var raitingControl: RaitingControl!
    
    
    var imageIsChange = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        newPlace?.defaultPlaces()
//        tableView.tableFooterView = UIView() //заменяем нижние строки таблицы на обычное View чтобы не было разделений а сплошная заливка
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1)) // чтобы скрыть последнее отделение строки от последующей пустоты, инициализируем нижний футер через фрэйм с координатами 0 0 шириной в размер таблицы и высотой 1 (чтобы перекрыть разделитель нижний)
        
        saveButton.isEnabled = false
        
        nameTF.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
        locationTF.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
        
        setupEditScreen()
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            let actionSheet = UIAlertController(title: nil, message: nil,
                                                preferredStyle: .actionSheet)
            let cameraIcon = #imageLiteral(resourceName: "camera")
            let photoIcon = #imageLiteral(resourceName: "photo")
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            cameraAction.setValue(cameraIcon, forKey: "image")
            cameraAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let photoAction = UIAlertAction(title: "Photo", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            photoAction.setValue(photoIcon, forKey: "image")
            photoAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            actionSheet.addAction(cameraAction)
            actionSheet.addAction(photoAction)
            actionSheet.addAction(cancelAction)
            
            present(actionSheet, animated: true)
            
            
            
        } else {
            view.endEditing(true)
        }
    }
    
//MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let mapVC = segue.destination as? MapViewController else {return} //проверяем что идентификатор доступен и можем скастить до нужного класса
        mapVC.incomeSegueIdentifier = identifier //передаем идентификатор
        mapVC.mapViewControllerDelegate = self
        if segue.identifier == "showMap"{
            mapVC.place.name = nameTF.text!
            mapVC.place.type = typeTF.text
            mapVC.place.location = locationTF.text!
            mapVC.place.imageData = newPlaceImage.image?.pngData()
        }else { return }
        
    }
    
    func savePlace() {
        let resImage = imageIsChange ? newPlaceImage.image : #imageLiteral(resourceName: "imagePlaceholder")
        
        let newPlace = Place(name: nameTF.text!,
                         location: locationTF.text,
                         type: typeTF.text,
                         imageData: resImage?.pngData(),
                         raiting: raitingControl.raiting)
        
        if currentPlace != nil{ //Если мы редактируем запись (т.е. на экран была передана информация) то мы не добавляем новую а редактируем текущую.
            //Делается следующим образом: пытаемся записать в базу, если успешно, присваиваем текущей строке в базе currentPlace (переданной на страницу редактирования) новые значения из newPlace (которые считаны уже с экрана)
            //В связи с этим не требуется никаких дополнительных методов Realm для редактирования или сохранения изменений, т.к. мы в текущем моменте производим изменения в базе по строке, которая была передана с начальной страницы в значение currentPlace текущей страницы (редактирования
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.raiting = newPlace.raiting
            }
        } else {
            StorageManage.saveObject(newPlace)
        }
        
        
    }
    
    private func setupEditScreen() {
        if currentPlace != nil {
            setupNavigationBar()
            imageIsChange = true
            
            guard let data = currentPlace?.imageData, let image = UIImage(data: data) else {return}
            guard let raiting = currentPlace?.raiting else {return}
            
            nameTF.text = currentPlace?.name
            locationTF.text = currentPlace?.location
            typeTF.text = currentPlace?.type
            raitingControl.raiting = raiting
            newPlaceImage.image = image
            newPlaceImage.contentMode = .scaleAspectFill
        }
    }
    
    private func setupNavigationBar() { //создаем метод для настройки NavigationBar при переходе на экран в качестве редактора
        if let topItem = navigationController?.navigationBar.topItem { //для того, чтобы удалить название кнопки (написано к какому контроллеру идет возврат) надо поменять название на пустое или любое другое
            topItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        }
        navigationItem.leftBarButtonItem = nil //убираем кнопку Cancel т.к. мы переходим для редактирования
        title = currentPlace?.name // передаем наименование текущего места
        saveButton.isEnabled = true //всегда активна, т.к. поля заполнены
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
}

extension NewPlaceController: UITextFieldDelegate{
//    Скрываем клавиатуру по кнопке Done
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldChange() {
        if nameTF.text?.isEmpty == false && locationTF.text?.isEmpty == false {
            saveButton.isEnabled = true
        }else {
            saveButton.isEnabled = false
        }
    }
}

extension NewPlaceController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func chooseImagePicker(source: UIImagePickerController.SourceType){
        if UIImagePickerController.isSourceTypeAvailable(source){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            present(imagePicker, animated: true, completion: nil)
        }
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        newPlaceImage.image = info[.editedImage] as? UIImage
        newPlaceImage.contentMode = .scaleAspectFill
        newPlaceImage.clipsToBounds = true
        imageIsChange = true
        dismiss(animated: true, completion: nil)
    }
}

extension NewPlaceController: MapViewControllerDelegate {  //расширяем под протокол который реализован на другом контроллере
    func getAddress(_ adress: String?) { // в adress уже содержится адрес
        locationTF.text = adress  //присваиваем куда нам надо
    }
}
