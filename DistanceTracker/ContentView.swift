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
    @StateObject var contactRetrievalService = ContactRetrievalService.shared
    @StateObject var remoteLocationService = LocationService.shared
    
    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (lat: Double, lon: Double) = (0, 0) 
    @State var distance: Double = 0
    
    @AppStorage("loggedIn") private var loggedIn = false

    var target: (lat: Double, lon: Double) = (54.9783, -1.6178)
    
    var body: some View {
        VStack(alignment: .leading){
            if loggedIn{
                locationStack
            }
//            formStack
            LoginPageView()
        }
    }
    
    private var formStack: some View {
        NavigationView {
            Form{
                ContactView()
                SettingsView()
                NotificationView()
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
            Text("Distance: \((distance * 1000).rounded() / 1000) km")
        }
        .padding()
        .onAppear {
            print("Just appeared")
            observeCoordinateUpates()
            observeLocationAccessDenied()
            observeDistanceUpdates()
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
                print("Received new coordinates: \(coordinates)")
                self.coordinates = (coordinates.latitude, coordinates.longitude)
                remoteLocationService.retrievePartnerLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            }
            .store(in : &tokens)
    }
    
    func observeLocationAccessDenied() {
        deviceLocationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Show some kind of alert to the user for location access denied")
            }
            .store(in: &tokens)
    }
    
    func observeDistanceUpdates() {
        remoteLocationService.distancePublisher
            .receive(on: DispatchQueue.main)
            .sink {completion in
                if case .failure(let error) = completion {
                    print("Received error on distance update: \(error)")
                }
            } receiveValue: { distance in
                self.distance = distance
                print("Distance updates to: \(distance)")
            }
            .store(in: &tokens)
    }
}

#Preview {
    ContentView()
}
