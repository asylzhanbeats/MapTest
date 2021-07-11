//
//  ViewController.swift
//  Map Test
//
//  Created by Assylzhan Nurlybekuly on 09.07.2021.
//

import UIKit
import MapKit
import CodableGeoJSON

class MapViewController: UIViewController {
    
    private let map = MKMapView()
    private let distanceLabel : UILabel = {
        let label = UILabel()
        label.layer.cornerRadius = 30
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.backgroundColor = .black
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }()
    private let overlays = [MKOverlay]()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(map)
        view.addSubview(distanceLabel)
        map.delegate = self
        setUpCoordinates()
    }
    private func setUpCoordinates(){
        let urlString = "https://waadsu.com/api/russia.geo.json" // API где дает geoJson
        
        // Конвертация на URL
        guard  let url = URL(string: urlString) else {
            print("error while conversion to URL??")
            return
        }
        // Запрос на сервер чтобы извлечь информацию
        URLSession.shared.dataTask(with: url,completionHandler: {[weak self]data,response,error in
            guard let strongSelf = self else {return}
            DispatchQueue.main.async {
                guard error == nil else {
                    print("ERROR??")
                    return}
                guard let data = data else {
                    print("NO DATA??")
                    return}
                
                // Декодирование GeoJson
                do {
                    switch try JSONDecoder().decode(GeoJSON.self, from: data) {
                       case .feature(let feature, _):
                        strongSelf.handleGeometry(feature.geometry)
                       case .featureCollection(let featureCollection, _):
                           for feature in featureCollection.features {
                            strongSelf.handleGeometry(feature.geometry)
                           }
                       case .geometry(let geometry, _):
                        strongSelf.handleGeometry(geometry)
                       }
                
                }catch{
                    fatalError("ERROR PARSING!\(error)")
                }
            }
        }).resume()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
        distanceLabel.frame = CGRect(x: 10, y: 50, width: view.frame.size.width-20, height: 52)
    }
    
    // Функция для разных геометрических объектов, в нашем случае есть только для мультиполигона
    private func handleGeometry(_ geometry: GeoJSON.Geometry?){
        guard let geometry = geometry else { return }
         switch geometry {
         case .point(_):
             break
         case .multiPoint(_):
             break
         case .lineString(_):
             break
         case .multiLineString(_):
             break
         case .polygon(_):
             break
         case .multiPolygon(let coordinates):
            display(coordinates)
             break
         case .geometryCollection(let geometries):
             for geometry in geometries {
                 handleGeometry(geometry)
             }
         }
    }
    private func display(_ coordinates: [PolygonGeometry.Coordinates]){
        
        // Getting all locations with longitudee and latitude
        var locations = [CLLocationCoordinate2D]()
        
        
        
        for coordinate in coordinates{
            for ring in coordinate {
                for pos in ring {
                        locations.append(CLLocationCoordinate2D(latitude: pos.latitude, longitude: pos.longitude))
                }
            }
        }
        let startPin = MKPointAnnotation()  // Начало Маршрута
        startPin.title = "Начало"
        startPin.coordinate = locations[0]
        map.addAnnotation(startPin)
        let endPin = MKPointAnnotation()        // Конец маршрута
        endPin.coordinate = locations[locations.count-1]
        endPin.title = "Конец"
        map.addAnnotation(endPin)
        
        // Делаем линию между каждой соседней парой чтобы выглядело как маршрут
        let polyLine = MKPolyline(coordinates: locations, count: locations.count)
        map.addOverlay(polyLine)
        let rect = polyLine.boundingMapRect
        map.setRegion(MKCoordinateRegion(rect), animated: true)
        
        
        // get the total distance
        var total: Double = 0.0
        for i in 0..<locations.count-1 {
            total += getDistance(from: locations[i], to: locations[i+1])
        }
        distanceLabel.text = "Длина маршрута: \(total/1000) километров"
        print("TOTAL DISTANCE: \(total) meters or \(total/1000) kilometers")
    }
    
    private func getDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
}


extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if (overlay is MKPolyline) {
                let pr = MKPolylineRenderer(overlay: overlay)
                pr.strokeColor = UIColor.blue.withAlphaComponent(0.5)
                pr.lineWidth = 5
                return pr
        }
        return MKOverlayRenderer()
    }
}
