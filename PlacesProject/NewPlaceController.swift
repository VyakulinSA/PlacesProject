//
//  NewPlaceController.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 16.08.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import UIKit

class NewPlaceController: UITableViewController {

    
    @IBOutlet weak var newPlaceImage: UIImageView!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var locationTF: UITextField!
    @IBOutlet weak var typeTF: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var newPlace: Place?
    var imageIsChange = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        newPlace?.defaultPlaces()
        tableView.tableFooterView = UIView()
        
        saveButton.isEnabled = false
        
        nameTF.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
        locationTF.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
        
        
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
    
    func saveNewPlace() {
        var resImage: UIImage?
        
        if imageIsChange == false{
            resImage = #imageLiteral(resourceName: "imagePlaceholder")
        }else {
            resImage = newPlaceImage.image
        }


//        newPlace = Place(name: nameTF.text!,
//                         location: locationTF.text,
//                         type: typeTF.text,
//                         image: resImage,
//                         restaurantImage: nil)
        
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

