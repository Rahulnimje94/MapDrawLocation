//
//  ViewController.swift
//  MapDrawLocation
//
//  Created by Anand Nimje on 22/02/18.
//  Copyright © 2018 Anand. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    fileprivate var locationCurrent = (lat: 0.0, long: 0.0)
    fileprivate var locationDestination = (lat: 13.0827, long: 80.2707)
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestForLocation(origin: String, destination: String){
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key=AIzaSyCCv8Le5XonwONQSy81pVhkDpcyc1Dv2u4"
        Alamofire.request(url, method: .get)
            .responseJSON { response in
                switch response.result {
                case .success:
                    self.getResponseFromGoogleApi(response.result.value as? [String: Any] ?? [:])
                case .failure(let error):
                    print(error)
                }
        }
    }
    
    func getResponseFromGoogleApi(_ response: [String: Any]){
        guard response.count != 0 else {
            return
        }
        let routes = response["routes"] as? [[String: Any]] ?? []
        routes.forEach{ drawRouteForMap($0) }
    }
    
    fileprivate func drawRouteForMap(_ route: [String: Any]){
        DispatchQueue.main.async { [weak self] in
            self?.mapView.clear()
            let routeOverviewPolyline = route["overview_polyline"] as? [String: Any] ?? [:]
            let points = routeOverviewPolyline["points"] as? String ?? ""
            let path = GMSPath.init(fromEncodedPath: points)
            let polyline = GMSPolyline.init(path: path)
            polyline.strokeWidth = 3
            let bounds = GMSCoordinateBounds(path: path!)
            self?.mapView!.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 30.0))
            polyline.map = self?.mapView
            self?.setDestinationLocationMarker()
        }
    }
    
    fileprivate func setDestinationLocationMarker(){
        let location = CLLocationCoordinate2D(latitude: locationDestination.lat,
                                              longitude: locationDestination.long)
        let marker = GMSMarker(position: location)
        marker.icon = UIImage(named: "current")
        marker.appearAnimation = .pop
        marker.map = mapView
        
        let locationOrigin = CLLocationCoordinate2D(latitude: locationCurrent.lat,
                                              longitude: locationCurrent.long)
        let markerOrigin = GMSMarker(position: locationOrigin)
        markerOrigin.icon = UIImage(named: "car")
        markerOrigin.appearAnimation = .pop
        markerOrigin.map = mapView
        
        //Set Zoom area
        mapView.animate(toZoom: 7)
    }
    
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        
        let origin = String(format: "%f,%f", location.coordinate.latitude, location.coordinate.longitude)
        let destination = String(format: "13.0827,80.2707")
        self.locationCurrent = (lat: location.coordinate.latitude,
                                long: location.coordinate.longitude)
        
        requestForLocation(origin: origin, destination: destination)
        
        // 8
        locationManager.stopUpdatingLocation()
    }
    
    
}

