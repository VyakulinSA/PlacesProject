//
//  MapManager.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 30.09.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager() //менеджер по управлению и настройкой геолокации
    
    private let regionInMeters =  100.00
    private var placeCoordinate: CLLocationCoordinate2D? //свойство для хранения координат места назначения
    private var directionsArray: [MKDirections] = [] //массив для хранения маршрутов и обновления его при смене маршрута
    
    
    func setupPlacemark(place: Place, mapView: MKMapView){
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
            annotation.title = place.name // в качестве заголовка аннотации будет название места
            annotation.subtitle = place.type // в качестве подзаголовка - тип места
            //далее нужно привязать аннтоацию к конкретной точке на карте в соответствии с местоположением маркера
            //для этого надо понять расположение маркера - пытаемся получить:
            guard let placemarkLocation = placemark?.location else {return}
            //если получилось достать положение, то привязываем аннотацию к месту на карте
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            // надо задать видимую область карты таким образом, чотбы было видно все созданные анотации
            //обращаемся к outlet карты на ViewController и передаем нашу аннотацию
            mapView.showAnnotations([annotation], animated: true) //сужает карту так, чтобы на ней отображались аннотации указанные в методе
            //чтобы выделить созданную аннотацию
            mapView.selectAnnotation(annotation, animated: true ) // позволяет подсветить (сделать крупнее) точку выделенную на карте
        }
    }
    
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> () ) {
        if CLLocationManager.locationServicesEnabled() { //показывает включены ли сервисы геоолокации
            //если включены, то вызываем настройку менеджера
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorisation(mapView: mapView, incomeSegueIdentifier: segueIdentifier) // вызываем метод проверки разрешения от пользователя
            closure()
        } else {
            //т.к данный метод находится во ViewDidLoad то он запускает все действия еще до загрузки страницы контроллера
            //поэтому необходимо вызов allert произвести чуть отложенно
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { //откладываем запуск на 1 секунду
                self.showAllert(title: "checkLocationServices", messge: "Else") //вызываем allert
            }
        }
    }
    
    //метод для проверки разрешения на использование геолокации от пользователя
    func checkLocationAuthorisation(mapView: MKMapView, incomeSegueIdentifier: String) {
        switch CLLocationManager.authorizationStatus() { //получение инфо о разрешении пользователя на использование
        case .authorizedWhenInUse: //разрешено когда используешь
            mapView.showsUserLocation = true
            if incomeSegueIdentifier ==  "getAdress" { showUserLocation(mapView: mapView) }
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
    
    func showUserLocation(mapView:MKMapView) {
        if let location = locationManager.location?.coordinate { //если координаты пользователя не пустые и их удалось определить
            //создаем регион на карте который отобразить
            let region = MKCoordinateRegion(center: location, //центр позиции на экране (положение пользователя)
                                            latitudinalMeters: regionInMeters, //размер широты в метрах
                                             longitudinalMeters: regionInMeters) //размер долготы в метрах
            //отобразим выделенный регион на экране
            mapView.setRegion(region, animated: true )
            
        }
    }
    //метод построения маршрута
    func getDirections(mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
         //первоначально определяем положение пользователя
        guard let location = locationManager.location?.coordinate else {
            showAllert(title: "Error", messge: "No user coordinate")
            return
        }
        //вызовем метод обновления локации у пользователя (данный режим включаем после того, как убедимся, что текущее местоположение пользователя определено см. выше)
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))  //передадим положение в свойство для отслеживания перемещения
        //построим запрос
        guard let request = createDirectionsRequest(from: location) else {
            showAllert(title: "Error", messge: "destination location not found")
            return
        }
        //строим маршрут
        let directions = MKDirections(request: request)
        //удаляем все старые маршруты
        resetMapView(withNew: directions, mapView: mapView)
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
                mapView.addOverlay(route.polyline) //polyline - подробная геометрия всего маршрута
                //сфокусируем карту так, чтобы весь маршрут был виден на карте
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) //MapRect - определяет зону видимости карты
                //поработаем с доп информацией
                let distance = String(format: "%.1f", route.distance / 1000) //дистанция в метрах, переводим в километры и округляем до 10х
                let timeInterval = lroundf(Float(route.expectedTravelTime / 60)) //время в минутах и округляем до целого
                //выведим на консоль информацию (при необходимости отобразим данную информацию в лэйбле, который необходимо скрывать до построения маршрута и отображать когда маршрут построен)
//                destinationAndTimeLabel.isHidden = false
//                destinationAndTimeLabel.text = "Расстояние до места: \(distance) км. Время: \(timeInterval) мин."
                print("Расстояние до места: \(distance) км. Время: \(timeInterval) мин.")
            }
        }
    }
    
    //метод настройки запроса для построения маршрута (принимает координаты -> возвращает запрос
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
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
    
    //метод для обновления карты при смене местоположения
    func starttrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        //убедимся что предыдущее значение локации пользователя не nil
        guard let location = location else {return}
        let center = getCenterLocation(for: mapView) //определим центр локации новый
        //будем обновлять локацию только в том случае, если расстояние между старым значением и новым центром будет более 50м
        //определим расстояние между точками
        guard center.distance(from: location) > 50 else {return}
//        //если больше, то обновим значение предыдущей локации присвоив текущее
//        self.previousLocation = center
//        //вызываем метод, чтобы спозиционировать карту по новым координатам
//        //только делать будем с задержкой, чтобы карта не сразу фокусировалась на новом местоположении и мы могли видеть перемещение точки
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.showUserLocation()
//        }
        closure(center)
    }
    
    func getCenterLocation (for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude //получаем широту
        let longitude = mapView.centerCoordinate.longitude //получаем долготу
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    //метод удаляет все маршруты с карты, его нужно вызывать перед тем как создать новый маршрут
    func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays) //удаляем все маршруты наложенные на карту
        //добавляем в массив текущие маршруты
        directionsArray.append(directions)
        //отключаем все маршруты
        let _ = directionsArray.map { $0.cancel() } //проходимся по каждому элементу массива и вызываем у него cancel
        //после чего удаляем все маршруты из массива
        directionsArray.removeAll()
    }
    
    func showAllert(title:String, messge:String){
        let alert = UIAlertController(title: title, message: messge, preferredStyle: .alert)
        let actionOk = UIAlertAction(title: "OK", style: .default)
        alert.addAction(actionOk)
        
        //Т.к. наш выделенный класс не подписан по UIViewController мы не можем просто вызвать метод present, для этого необходимо
        let allertWindow = UIWindow(frame: UIScreen.main.bounds) //определяем окно по границе экрана
        allertWindow.rootViewController = UIViewController() //инициализируем рут контроллер как UIViewController
        //определяем позиционирование относительно других окон
        allertWindow.windowLevel = UIWindow.Level.alert + 1
        //сделаем окно видимым
        allertWindow.makeKeyAndVisible()
        //вызовем present
        allertWindow.rootViewController?.present(alert,animated: true)
  
    }
}
