//
//  DeviceLocationService.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 16/03/2025.
//


import Combine
import CoreLocation

class DeviceLocationService: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    var coordinatesPublisher = PassthroughSubject<CLLocationCoordinate2D, Error>()
    
    var deniedLocationAccessPublisher = PassthroughSubject<Void, Never>()
    
    private override init(){
        super.init()
    }
    
    static let shared = DeviceLocationService()
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5.0 // 5.0 Meters
        manager.delegate = self
        return manager
    }()
    
    func requestLocationUpdates() {
        print("Reuqesting location updates")
        switch locationManager.authorizationStatus {
            
        case .notDetermined:
            print("Reuqesting always auth")
            locationManager.requestAlwaysAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways, .authorized:
            print("Authorized")
            locationManager.startUpdatingLocation()
            
        default:
            print("Something else \(locationManager.authorizationStatus)")
            deniedLocationAccessPublisher.send()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            
        default:
            manager.stopUpdatingLocation()
            deniedLocationAccessPublisher.send()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinatesPublisher.send(location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        coordinatesPublisher.send(completion: .failure(error))
    }
}
