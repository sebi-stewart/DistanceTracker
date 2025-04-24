//
//  NotificationView.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 21/04/2025.
//
import SwiftUI
import Foundation
import MapKit

struct NotificationView: View{
    @State private var showNotificationSettings = UserDefaults.standard.bool(forKey: "notificationsOn")
    @State var notSetting1: Int = 0
    @State var dateSetting1: Date = Date.now
    
    @State var scheduledNotifications: [Date] = []
    @State var distanceNotificationValues: [Double] = []
    @AppStorage("distanceMeasurement")  var distanceMeasurementInt: Int = 0 // Either 0 for km/meters or 1 for mile/yards
    
//    @FocusState private var isTextFieldFocused: Bool
        
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
        NavigationStack {
            Form{
                distanceNotificationSection
                scheduledNotificationSection
            }
        }
//        .toolbar {
//            ToolbarItemGroup(placement: .keyboard) {
//                Spacer()
//                Button("Done") {
//                    isTextFieldFocused = false
//                }
//            }
//        }
    }
    
    var distanceNotificationSection: some View {
        Section(header: Text("Distance Notifications")) {
            ForEach(distanceNotificationValues.indices, id: \.self) { index in
                HStack{
                    StepperView(value: $distanceNotificationValues[index],
                                distanceMeasurement: DistanceMeasurements(rawValue: distanceMeasurementInt)!
                        )
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
//        .toolbar {
//            if isTextFieldFocused {
//                ToolbarItemGroup(placement: .keyboard) {
//                    Spacer()
//                    Button("Done") {
//                        isTextFieldFocused = false
//                    }
//                }
//            }
//        }
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

