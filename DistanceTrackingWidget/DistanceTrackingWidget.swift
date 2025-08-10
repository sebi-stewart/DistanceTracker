//
//  DistanceTrackingWidget.swift
//  DistanceTrackingWidget
//
//  Created by Sebastian Stewart on 23/07/2025.
//

import WidgetKit
import SwiftUI
import Combine
import Darwin

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<SimpleEntry>) -> Void) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline =  Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct DistanceTrackingWidgetEntryView : View {
    @StateObject var deviceLocationService = DeviceLocationService.shared
    @StateObject var remoteLocationService = LocationService.shared
    
    @AppStorage("loggedIn") private var loggedIn = true
    
    @State var tokens: Set<AnyCancellable> = []
    
    @State var coordinates: (lat: Double, lon: Double) = (0, 0)
    @State var distance: Double = 0


    var entry: Provider.Entry

    var body: some View {
        VStack {
            if loggedIn{
                locationStack
            }
        }
    }
    
    private var locationStack: some View {
        VStack {
            Text("Lat: \(coordinates.lat)")
                .font(.title)
            Text("Lon: \(coordinates.lon)")
                .font(.title)
            Text("Dis in km:")
            Text("\((distance * 1000).rounded() / 1000)")
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

@main
struct DistanceTrackingWidget: Widget {
    let kind: String = "DistanceTrackingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DistanceTrackingWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

#Preview(as: .systemSmall) {
    DistanceTrackingWidget()
} timeline: {
    SimpleEntry(date: .now)
}
