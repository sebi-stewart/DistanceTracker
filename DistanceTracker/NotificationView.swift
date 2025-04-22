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
    @State var distanceNotifications: [StepperView] = []
        
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
        .onAppear{
            print("Updating Measurements - child")
            for distanceNotification in distanceNotifications {
                distanceNotification.updateMeasurement()
            }
            print("Done Updating - child")
        }
    }
    
    var distanceNotificationSection: some View {
        Section(header: Text("Distance Notifications")) {
            ForEach(distanceNotifications.indices, id: \.self) { index in
                HStack{
                    distanceNotifications[index]
                    Button(action: {
                        print("Button pressed: \(index+1)")
                        distanceNotifications.remove(at: index)
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(Color.blue)
                    }.buttonStyle(BorderlessButtonStyle())
                }
            }
            Button(action: {
                let newStepper = StepperView()
                distanceNotifications.append(newStepper)
            }) {
                HStack{
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color.blue)
                    Text("Add Scheduled Notification")
                }
            }
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
                        print("Button pressed: \(index+1)")
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
    @State private var value = 0
    @AppStorage("distanceMeasurement") var distanceMeasurementInt: Int = 0
    @State var measurement: String = DistanceMeasurements(rawValue: UserDefaults.standard.integer(forKey: "distanceMeasurement"))!.description
    let maxStep = 1000000


    func incrementStep() {
        value = Int(pow(10, log10(Double(value+1)).rounded(.up)))
        if value >= maxStep { value = 0 }
    }


    func decrementStep() {
        if value <= 0 { value = maxStep; return }
        value =  Int(pow(10, log10(Double(value-1)).rounded(.down)))
    }
    
    func updateMeasurement() {
        print("Should be: " + (DistanceMeasurements(rawValue: UserDefaults.standard.integer(forKey: "distanceMeasurement"))!.description))
        print("Is: " + DistanceMeasurements(rawValue: distanceMeasurementInt)!.description)
    }


    var body: some View {
        Stepper {
            Text("\(value) \(DistanceMeasurements(rawValue: distanceMeasurementInt)!.description)")
        } onIncrement: {
            incrementStep()
        } onDecrement: {
            decrementStep()
        } .onChange(of: distanceMeasurementInt) {
            print("Changed, updating value \(value)")
            if distanceMeasurementInt == 0 { // Handle changing from miles to km
                value = Int(Double(value) * 1.60934)
            }
            if distanceMeasurementInt == 1 { // Handle changing from km to miles
                value = Int(Double(value) * 0.621371)
            }
        }
    }
}
