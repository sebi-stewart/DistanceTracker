//
//  ContentView.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 16/03/2025.
//

import SwiftUI
import Combine
import Darwin

struct ContentView: View {
    @StateObject var deviceLocationService = DeviceLocationService.shared
    
    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (lat: Double, lon: Double) = (0, 0)
    @State var distance: Double = 0
    var target: (lat: Double, lon: Double) = (54.9783, -1.6178)
    
    var body: some View {
        VStack(alignment: .leading){
            locationStack
            Form{
                ContactView()
                SettingsView()
            }
        }
    }
    
    private var locationStack: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Latitutde: \(coordinates.lat)")
                .font(.title)
            Text("Longitude: \(coordinates.lon)")
                .font(.title)
            Text("Distance: \((distance * 10).rounded() / 10) km")
        }
        .padding()
        .onAppear {
            observeCoordinateUpates()
            observeLocationAccessDenied()
            deviceLocationService.requestLocationUpdates()
        }
    }
    
    func observeCoordinateUpates() {
        deviceLocationService.coordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink {completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            } receiveValue: { coordinates in
                self.coordinates = (coordinates.latitude, coordinates.longitude)
                self.distance = updateDistanceToTarget()
            }
            .store(in : &tokens)
    }
    
    func observeLocationAccessDenied() {
        deviceLocationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Show some kind of alert to the user")
            }
            .store(in: &tokens)
    }
    
    func updateDistanceToTarget() -> Double{
        let radius: Double = 6371.0 //km
        let pi = Double.pi
        
        let a = (0.5 - cos((target.lat - coordinates.lat) * pi) / 2
                     + cos(coordinates.lat * pi) * cos(target.lat * pi) *
                 (1 - cos((target.lon - coordinates.lon) * pi)) / 2)
        return (2 * radius * asin(sqrt(a)))
        
    }
}

#Preview {
    ContentView()
}
