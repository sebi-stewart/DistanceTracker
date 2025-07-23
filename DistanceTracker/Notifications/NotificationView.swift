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
    @AppStorage("notificationsOn") private var showNotificationSettings = false
    @State var notSetting1: Int = 0
    @State var dateSetting1: Date = Date.now
    
    @StateObject var notificationService = NotificationService.shared
    
    @AppStorage("distanceNotifications") var distanceNotificationValues: [Double] = []
    @AppStorage("scheduledNotifications") var scheduledNotifications: [Date] = []
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
            formatter.dateFormat = "HH:mm"
        }
        .onChange(of: scheduledNotifications){
            print("Scheduled notifications - onChange")
            notificationService.scheduleNotifications()
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

struct NotificationView_Previews: PreviewProvider{
    static var previews: some View {
        NotificationView()
    }
}


extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
