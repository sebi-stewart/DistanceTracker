//
//  SettingsComponent.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 20/04/2025.
//

import SwiftUI

struct SettingsView: View{
    let measurements = ["kilometer", "miles"]
    @State var selectedMeasurement: Int = 0
    
    var body: some View {
        Section {
            Picker("Distance Measurement:", selection: $selectedMeasurement) {
                Text("Kilometers").tag(0)
                Text("Miles").tag(1)
            }
        }
    }
}
