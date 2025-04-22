//
//  SettingsComponent.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 20/04/2025.
//

import SwiftUI

enum DistanceMeasurements: Int{
    case kilometers
    case miles
    
    var description: String {
        switch self {
        case .kilometers: return "kilometers"
        case .miles: return "miles"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .kilometers: return "km"
        case .miles: return "mi"
        }
    }
}

class DistanceObservable: ObservableObject {
    @Published var description: String = ""
}

struct SettingsView: View{
    @State var selectedMeasurement: Int = UserDefaults.standard.integer(forKey: "distanceMeasurement")
    
    var body: some View {
        Section(header: Text("Settings")) {
            Picker("Distance Measurement:", selection: $selectedMeasurement) {
                Text("Kilometers").tag(0)
                Text("Miles").tag(1)
            }
            .onChange(of: selectedMeasurement){
                UserDefaults.standard.set(selectedMeasurement, forKey: "distanceMeasurement")
            }
            .onAppear{
                selectedMeasurement = UserDefaults.standard.integer(forKey: "distanceMeasurement")
            }
            
        }
    }
}
