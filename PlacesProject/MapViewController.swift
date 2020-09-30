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


    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pinOutlet: UIImageView!
    @IBOutlet weak var curentAdressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var destinationAndTimeLabel: UILabel!
    
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    let annotationIdentifier = "annotationIdentifier" //создаем уникальный идентификатор аннотации, для переиспользования аннотаций
    let locationManager = CLLocationManager() //менеджер по управлению и настройкой геолокации
    var incomeSegueIdentifier = "" //передаем идентификатор по которому происходит переход на контроллер
    let regionInMeters =  100.00
    var placeCoordinate: CLLocationCoordinate2D? //свойство для хранения координат места назначения
    var directionsArray: [MKDirections] = [] //массив для хранения маршрутов и обновления его при смене маршрута
    var previousLocation: CLLocation? {  //свойство для хранения предыдущего местоположения
        didSet{ //при изменении свойства, будет вызываться метод обновления позиции на карте по определенным условиям
            starttrackingUserLocation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        curentAdressLabel.text = ""
        showMap()
        checkLocationServices()

    }

    @IBAction func cancelMap() {
        dismiss(animated: true)
    }
    

    
    @IBAction func uselLocation() {
        showUserLocation()
    }
    
    
    @IBAction func doneButtonPress() {
        mapViewControllerDelegate?.getAddress(curentAdressLabel.text)
        dismiss(animated: true) 
    }
    
    @IBAction func goButtonPressed() {
        //метод построения маршрута
        getDirections()
    }
    
    
    private func showMap() {
        goButton.isHidden = true
        destinationAndTimeLabel.isHidden = true
        
        if incomeSegueIdentifier == "showMap" { //в зависимости от того по какому segue переходим, запускаем разные вариации
            setupPlacemark()
            pinOutlet.isHidden = true
            curentAdressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
    //метод удаляет все маршруты с карты, его нужно вызывать перед тем как создать новый маршрут
    private func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays) //удаляем все маршруты наложенные на карту
        //добавляем в массив текущие маршруты
        directionsArray.append(directions)
        //отключаем все маршруты
        let _ = directionsArray.map { $0.cancel() } //проходимся по каждому элементу массива и вызываем у него cancel
        //после чего удаляем все маршруты из массива
        directionsArray.removeAll()
    }
    
    private func setupPlacemark(){
        guard let location = place.location else {return} //извлекаем положение
        
        let geocoder = CLGeocoder() // конвертер координат(долготы и широты) в читаемый формат
        geocoder.geocodeAddressString(location) { (placemarks , error) in //метод определяющий координаты по адресу и возвращающий ошибку если что
        //проверяем не содержит ли метод ошибок, и если ошибка не равна nil, то выводим ошибку, если nil то идем дальше
            if let error = error {
                print(error)
                return
            }
            //если ошибки нет, то пытаемся получить метки placemarks
            guard let placemarks = placemarks else {return}
            //получаем метку из массива меток (она должна быть одна, поэтому берем first)
            let placemark = placemarks.first
            //пытаемся получить информацию из маркера, но так как он ничего кроме координат не содержит, создаем класс для аннотации
            //аннотация - именно скрепка на карте
            let annotation = MKPointAnnotation() //используется для того, чтобы описать какую то точку на карте
            annotation.title = self.place.name // в качестве заголовка аннотации будет название места
            annotation.subtitle = self.place.type // в качестве подзаголовка - тип места
            
            
            //далее нужно привязать аннтоацию к конкретной точке на карте в соответствии с местоположением маркера
            //для этого надо понять расположение маркера - пытаемся получить:
            guard let placemarkLocation = placemark?.location else {return}
            
            //если получилось достать положение, то привязываем аннотацию к месту на карте
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            
            // надо задать видимую область карты таким образом, чотбы было видно все созданные анотации
            //обращаемся к outlet карты на ViewController и передаем нашу аннотацию
            self.mapView.showAnnotations([annotation], animated: true) //сужает карту так, чтобы на ней отображались аннотации указанные в методе
            //чтобы выделить созданную аннотацию
            self.mapView.selectAnnotation(annotation, animated: true ) // позволяет подсветить (сделать крупнее) точку выделенную на карте

        }
    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() { //показывает включены ли сервисы геоолокации
            //если включены, то вызываем настройку менеджера
            setupLocationManager()
            checkLocationAuthorisation() // вызываем метод проверки разрешения от пользователя
            
        } else {
            //т.к данный метод находится во ViewDidLoad то он запускает все действия еще до загрузки страницы контроллера
            //поэтому необходимо вызов allert произвести чуть отложенно
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { //откладываем запуск на 1 секунду
                self.showAllert(title: "checkLocationServices", messge: "Else") //вызываем allert
            }
            
        }
    }
    
    //метод по настройке менеджера локации
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //устанавливаем точность определения локации (выбрали самую точную)
    }
    
    //метод для проверки разрешения на использование геолокации от пользователя
    private func checkLocationAuthorisation() {
        switch CLLocationManager.authorizationStatus() { //получение инфо о разрешении пользователя на использование
        case .authorizedWhenInUse: //разрешено когда используешь
            mapView.showsUserLocation = true
            if incomeSegueIdentifier ==  "getAdress" { showUserLocation() }
            break
        case .denied: //отключено использование локации
            self.showAllert(title: "denied", messge: "denied")
            break
        case . notDetermined: // пользователь не определился разрешить ли использование
            locationManager.requestWhenInUseAuthorization() //сделать запрос на использование геолокации
            break
        case .restricted: //приложение не авторизовано для вызова служб геолокации
            self.showAllert(title: "restricted", messge: "restricted")
            break
        case .authorizedAlways: //разрешено постоянно
            break
        @unknown default: // ветка которая сработает если в будущем у перечисления появится новый кейс
            print ("New case")
        }
    }
    
    private func showAllert(title:String, messge:String){
        let alert = UIAlertController(title: title, message: messge, preferredStyle: .alert)
        let actionOk = UIAlertAction(title: "OK", style: .default)
        alert.addAction(actionOk)
        present(alert,animated: true)
    }
    
    private func getCenterLocation (forMapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude //получаем широту
        let longitude = mapView.centerCoordinate.longitude //получаем долготу
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func showUserLocation() {
        if let location = locationManager.location?.coordinate { //если координаты пользователя не пустые и их удалось определить
            //создаем регион на карте который отобразить
            let region = MKCoordinateRegion(center: location, //центр позиции на экране (положение пользователя)
                                            latitudinalMeters: regionInMeters, //размер широты в метрах
                                             longitudinalMeters: regionInMeters) //размер долготы в метрах
            //отобразим выделенный регион на экране
            mapView.setRegion(region, animated: true )
            
        }
    }
    
    //метод для обновления карты при смене местоположения
    private func starttrackingUserLocation() {
        //убедимся что предыдущее значение локации пользователя не nil
        guard let previousLocation = previousLocation else {return}
        let center = getCenterLocation(forMapView: mapView) //определим центр локации новый
        //будем обновлять локацию только в том случае, если расстояние между старым значением и новым центром будет более 50м
        //определим расстояние между точками
        guard center.distance(from: previousLocation) > 50 else {return}
        //если больше, то обновим значение предыдущей локации присвоив текущее
        self.previousLocation = center
        //вызываем метод, чтобы спозиционировать карту по новым координатам
        //только делать будем с задержкой, чтобы карта не сразу фокусировалась на новом местоположении и мы могли видеть перемещение точки
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()
        }
        
    }
    
    //метод построения маршрута
    private func getDirections() {
         //первоначально определяем положение пользователя
        guard let location = locationManager.location?.coordinate else {
            showAllert(title: "Error", messge: "No user coordinate")
            return
        }
        
        //вызовем метод обновления локации у пользователя (данный режим включаем после того, как убедимся, что текущее местоположение пользователя определено см. выше)
        locationManager.startUpdatingLocation()
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)  //передадим положение в свойство для отслеживания перемещения
        
        //построим запрос
        guard let request = createDirectionsRequest(from: location) else {
            showAllert(title: "Error", messge: "destination location not found")
            return
        }
        //строим маршрут
        let directions = MKDirections(request: request)
        //удаляем все старые маршруты
        resetMapView(withNew: directions)
        
        //рассчитываем маршрут c новыми входными данными
        directions.calculate { (response, error) in
            if let error = error {
                print(error)
                return
            }
            //пробуем извлечь обработанный маршрут
            guard let response = response else {
                self.showAllert(title: "Error", messge: "no response")
                return
            }
            //объект response содержит всебе массив с маршрутами
            for route in response.routes {
                // каждый маршрут содержит в себе геометрию а так же доп информацию (ожидаемое время пути), которую можно отобразить на карте
                self.mapView.addOverlay(route.polyline) //polyline - подробная геометрия всего маршрута
                //сфокусируем карту так, чтобы весь маршрут был виден на карте
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) //MapRect - определяет зону видимости карты
                //поработаем с доп информацией
                let distance = String(format: "%.1f", route.distance / 1000) //дистанция в метрах, переводим в километры и округляем до 10х
                let timeInterval = lroundf(Float(route.expectedTravelTime / 60)) //время в минутах и округляем до целого
                //выведим на консоль информацию (при необходимости отобразим данную информацию в лэйбле, который необходимо скрывать до построения маршрута и отображать когда маршрут построен)
                 
                self.destinationAndTimeLabel.isHidden = false
                self.destinationAndTimeLabel.text = "Расстояние до места: \(distance) км. Время: \(timeInterval) мин."
            }
        }
    }
    
    //метод настройки запроса для построения маршрута (принимает координаты -> возвращает запрос
    private func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        //попытаемся получить координаты места назначения
        guard let distinationCoordinate = placeCoordinate else {return nil}
        //получаем стартовую точку (мы ее будем получать в метод)
        let startingLocation = MKPlacemark(coordinate: coordinate)
        //получаем конечную точку
        let destination = MKPlacemark(coordinate: distinationCoordinate)
        //имея 2 точки на карте, мы можем создать запрос на прокладку маршрута
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation) //начало маршрута
        request.destination = MKMapItem(placemark: destination)
        //задодим тип транспорта
        request.transportType = .automobile //здесь жестко указано, я думаю можно передавать значения через параметры метода
        request.requestsAlternateRoutes = true //указываем возможность построить альтернативные маршруты, если их несколько
        
        return request
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
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier) //создаем анотацию как текущую анотацию
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
        let center = getCenterLocation(forMapView: mapView) //определяем текущий центр
        let geocoder = CLGeocoder() // конвертер координат(долготы и широты) в читаемый формат
        
        if incomeSegueIdentifier == "showMap" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { //через каждые 3 секунды фокусируемся на точке пользователя
                self.showUserLocation()
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
        checkLocationAuthorisation() //вызываем необходимыые действия при той или иной авторизации пользователя
    }
    
     
}
