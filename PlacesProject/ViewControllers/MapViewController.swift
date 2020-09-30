//
//  MapViewController.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 28.09.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func getAddress (_ adress: String?)
}

class MapViewController: UIViewController {
    
    let mapManager = MapManager()
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    
    let annotationIdentifier = "annotationIdentifier" //создаем уникальный идентификатор аннотации, для переиспользования аннотаций
    var incomeSegueIdentifier = "" //передаем идентификатор по которому происходит переход на контроллер
    
    var previousLocation: CLLocation? {  //свойство для хранения предыдущего местоположения
        didSet{ //при изменении свойства, будет вызываться метод обновления позиции на карте по определенным условиям
            mapManager.starttrackingUserLocation(
                for: mapView,
                and: previousLocation) { (currentLocation) in
                
                self.previousLocation = currentLocation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.mapManager.showUserLocation(mapView: self.mapView)
                }
            }
        }
    }
    

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pinOutlet: UIImageView!
    @IBOutlet weak var curentAdressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var destinationAndTimeLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        curentAdressLabel.text = ""
        showMap()
    }

    @IBAction func cancelMap() {
        dismiss(animated: true)
    }

    @IBAction func uselLocation() {
        mapManager.showUserLocation(mapView: mapView)
    }
    
    @IBAction func doneButtonPress() {
        mapViewControllerDelegate?.getAddress(curentAdressLabel.text)
        dismiss(animated: true) 
    }
    
    @IBAction func goButtonPressed() {
        //метод построения маршрута
        mapManager.getDirections(mapView: mapView) { (location) in
            self.previousLocation = location
        }
    }
    
    
    private func showMap() {
        goButton.isHidden = true
        destinationAndTimeLabel.isHidden = true
        
        mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        if incomeSegueIdentifier == "showMap" { //в зависимости от того по какому segue переходим, запускаем разные вариации
            mapManager.setupPlacemark(place: place, mapView: mapView)
            pinOutlet.isHidden = true
            curentAdressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
}

//добавим расширение для возможности работать с аннотациями на карте
extension MapViewController: MKMapViewDelegate{
    
    //сделаем отображение аннотации
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {return nil} //проверяем, что выбранная аннотация не является текущим положением пользователя
        //далее необходимо создать AnnotationView с которым мы будем работать
        //но в документации рекомендуютБ использовать ранее открытые анотации, а не создавать новые
        //поэтому используем метод
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier ) as? MKPinAnnotationView //приводим к типу MKPinAnnotationView для отображения булавки (Pin тоже самое что и обычный ViewБ с дополнительными ништяками)
        
        if annotationView == nil { //если у нас на карте нет аннотаций
            annotationView = MKPinAnnotationView(annotation: annotation,
                                                 reuseIdentifier: annotationIdentifier) //создаем анотацию как текущую анотацию
            annotationView?.canShowCallout = true //для отображения банера анотации
        }
        if let imageData = place.imageData{
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50)) //объявляем представление для изображения на банере (задаем размеры и положение)
            imageView.layer.cornerRadius = 10 //срежем углы
            imageView.clipsToBounds = true //сделаем обрезку по углам
            imageView.image = UIImage(data: imageData) // получим изображение
            annotationView?.rightCalloutAccessoryView = imageView // присвоим на банере справа - наше изображение
        }
        return annotationView
    }
    
    //данный метод будет вызываться всегда при смене координат региона
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //каждый раз при смене координат, мы будем отображать новый адрес
        let center = mapManager.getCenterLocation(for: mapView) //определяем текущий центр
        let geocoder = CLGeocoder() // конвертер координат(долготы и широты) в читаемый формат
        
        if incomeSegueIdentifier == "showMap" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { //через каждые 3 секунды фокусируемся на точке пользователя
                self.mapManager.showUserLocation(mapView: self.mapView)
            }
        }
        
        //для освобождения ресурсов связанных с геокодированием рекомендуется делать отмену отложенного запроса
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in//метод определяющий координаты по адресу и возвращающий ошибку если что
            //проверяем не содержит ли метод ошибок, и если ошибка не равна nil, то выводим ошибку, если nil то идем дальше
            if let error = error {
                print(error)
                return
            }
            //если ошибки нет, то пытаемся получить метки placemarks
            guard let placemarks = placemarks else {return}
            //получаем метку из массива меток (она должна быть одна, поэтому берем first)
            let placemark = placemarks.first
            let street = placemark?.thoroughfare //извлекаем улицу
            let buildNumber = placemark?.subThoroughfare //извлекаем номер дома
            
            DispatchQueue.main.async { //делать обновление нужно асинхронно
                if street != nil, buildNumber != nil {
                    self.curentAdressLabel.text = "\(street!), \(buildNumber!)"  //присваиваем в лэйбл
                } else if street != nil{
                    self.curentAdressLabel.text = "\(street!)"
                } else {
                    self.curentAdressLabel.text = ""
                }
            }
        }
    }
    
    //подсвечиваем маршрут
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //мы создали маршрут, но он невидимый, для его отображения покрасим линию
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline) //отрендерим маршрут
        renderer.strokeColor = .green //покрасим
        
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate{ //для отслеживания в реальном времени статуса возможности использовать геопозицию необходимо подписать под делегата
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) { //метод запускающийся при изменении статуса авторизации
        mapManager.checkLocationAuthorisation(mapView: mapView,
                                              incomeSegueIdentifier: incomeSegueIdentifier) //вызываем необходимыые действия при той или иной авторизации пользователя
    }
    
     
}
