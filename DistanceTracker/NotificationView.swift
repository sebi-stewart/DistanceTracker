//
//  NotificationView.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 21/04/2025.
//
import SwiftUI
import Foundation

struct NotificationView: View{
    @State private var showNotificationSettings = UserDefaults.standard.bool(forKey: "notificationsOn")
    @State var notSetting1: Int = 0
    @State var dateSetting1: Date = Date.now
    
    @State var scheduledNotifications: [Date] = []
    @State var distanceNotificationValues: [Double] = []
    @AppStorage("distanceMeasurement")  var distanceMeasurementInt: Int = 0 // Either 0 for km/meters or 1 for mile/yards
        
    let formatter = DateFormatter()
    
    var body: some View {
        Section(header: Text("Notifications")) {
            Toggle("Enable Notifications", isOn: $showNotificationSettings)
            if showNotificationSettings{
                NavigationLink("Notification Settings", destination: notificationPageView)
            }
        }
        .onAppear{
            showNotificationSettings = UserDefaults.standard.bool(forKey: "notificationsOn")
            formatter.dateFormat = "HH:mm"
        }
        .onChange(of: showNotificationSettings){
            UserDefaults.standard.set(showNotificationSettings, forKey: "notificationsOn")
        }
    }
    
    var notificationPageView: some View {
        NavigationView {
            Form{
                distanceNotificationSection
                scheduledNotificationSection
            }
        }
    }
    
    var distanceNotificationSection: some View {
        Section(header: Text("Distance Notifications")) {
            ForEach(distanceNotificationValues.indices, id: \.self) { index in
                HStack{
                    StepperView(value: $distanceNotificationValues[index],
                                distanceMeasurement: DistanceMeasurements(rawValue: distanceMeasurementInt)!)
                    Button(action: {
                        print("Button pressed: \(index)")
                        distanceNotificationValues.remove(at: index)
                        print(distanceNotificationValues)
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(Color.blue)
                    }.buttonStyle(BorderlessButtonStyle())
                }
            }
            Button(action: {
                distanceNotificationValues.append(0)
            }) {
                HStack{
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color.blue)
                    Text("Add Scheduled Notification")
                }
            }
        }
        .onDisappear{
            print("Printing on main dissapear")
            print(distanceNotificationValues)
            print("Done printing on main dissapear")
        }
    }
    
    var scheduledNotificationSection: some View {
        Section(header: Text("Scheduled Notifications")) {
            ForEach(scheduledNotifications.indices, id: \.self) { index in
                HStack{
                    DatePicker(
                        String("Notification: \(index+1)"),
                        selection: $scheduledNotifications[index],
                        displayedComponents: [.hourAndMinute]
                    )
                    Button(action: {
                        print("Scheduled Remove Button pressed: \(index)")
                        scheduledNotifications.remove(at: index)
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(Color.blue)
                    }.buttonStyle(BorderlessButtonStyle())
                }
            }
            Button(action: {
                scheduledNotifications.append(getStartOfDay())
            }) {
                HStack{
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color.blue)
                    Text("Add Scheduled Notification")
                }
            }
        }
    }
    
    func getStartOfDay() -> Date {
        return Calendar.current.startOfDay(for: Date())
    }
}

struct StepperView: View {
    @Binding var value: Double
    @State var distanceMeasurement: DistanceMeasurements = .kilometers
    let maxStep = 20037.0 // This is the antipodal distance of earth, aka furthest point you can be away from one another

    func incrementStep() {
        if value == maxStep { value = 0; return}
        var displayValue = convertToSelectedMeasurement()
        displayValue = pow(10, log10(Double(displayValue+1)).rounded(.up))
        value = convertFromSelectedMeasurement(newValue: displayValue)
        if value >= maxStep { value = maxStep }
    }

    func decrementStep() {
        if value <= 0 { value = maxStep; return}
        var displayValue = convertToSelectedMeasurement()
        displayValue =  pow(10, log10(Double(displayValue-1)).rounded(.down))
        value = convertFromSelectedMeasurement(newValue: displayValue)
    }
    
    func updateDistanceMeasurement() {
        if value < 3{
            distanceMeasurement = distanceMeasurement.smallerMeasurements
        } else if value > 3 {
            distanceMeasurement = distanceMeasurement.largerMeasurements
        }
        
    }
    
    func convertToSelectedMeasurement() -> Double {
        return value * distanceMeasurement.conversionFromKM
    }
    
    func convertFromSelectedMeasurement(newValue: Double) -> Double {
        return newValue / distanceMeasurement.conversionFromKM
    }


    var body: some View {
        Stepper {
            Text("\(Int(convertToSelectedMeasurement().rounded())) \(distanceMeasurement.description)")
        } onIncrement: {
            incrementStep()
            updateDistanceMeasurement()
        } onDecrement: {
            decrementStep()
            updateDistanceMeasurement()
        } .onAppear {
            updateDistanceMeasurement()
        }
    }
}
