//
//  LocationService.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 23/07/2025.
//

import Combine
import CoreLocation

class LocationService: NSObject, ObservableObject {
    
    private override init(){
        super.init()
    }
    
    enum DistanceError: Error {
        case unpacking(String)
        case request(Int)
    }
    
    static let shared = LocationService()
    private weak var previousDistanceRequest: URLSessionTask?
    
    var distancePublisher = PassthroughSubject<Double, Error>()
    
    func retrievePartnerLocation(latitude: Double, longitude: Double) {
        print("Retrieving partners location with \(latitude) : \(longitude)")
        previousDistanceRequest?.cancel()
        let loginBody = ["latitude": latitude, "longitude": longitude] as Dictionary<String, Double>
        
        var request = URLRequest(url: URL(string: "http://localhost:65300/distance")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: loginBody, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        previousDistanceRequest = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            
            guard let httpResponse = response as? HTTPURLResponse else { self.distanceManager(didFailWithError: DistanceError.request(400)); return}
            guard httpResponse.statusCode == 200 else { self.distanceManager(didFailWithError: DistanceError.request(httpResponse.statusCode)); return }

            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, Double>
                if let distance = json["distance"] {
                    self.distanceManager(distance: distance)
                    return
                }
                self.distanceManager(didFailWithError: DistanceError.unpacking("Distance not included in response"))
            } catch {
                self.distanceManager(didFailWithError: error)
            }

        })
        
        previousDistanceRequest!.resume()
        
    }
    
    func distanceManager(distance: Double) {
        guard distance >= 0 else { return }
        distancePublisher.send(distance)
    }
    
    func distanceManager(didFailWithError error: any Error) {
        distancePublisher.send(completion: .failure(error))
    }
}
