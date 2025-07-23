//
//  NotificationController.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 26/04/2025.
//

import SwiftUI
import Foundation
import UserNotifications

class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    var notificationsAllowed: Bool? = nil
    @AppStorage("distanceNotifications") private var distanceNotification: [Double] = []
    @AppStorage("scheduledNotifications") private var scheduledNotifications: [Date] = []
    let notificationIdentifier: String = "alarm"
    
    private override init(){
        super.init()
    }
    
    static let shared = NotificationService()
    
    private lazy var notificationCenter: UNUserNotificationCenter = {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in print("Permission granted: \(granted)")
            guard granted else { return }
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                print("Notification settings: \(settings)")
                guard settings.authorizationStatus == .authorized else { return }
                
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        let show = UNNotificationAction(identifier: "show", title: "Tell me more…", options: .foreground)
        let category = UNNotificationCategory(identifier: notificationIdentifier, actions: [show], intentIdentifiers: [])

        center.setNotificationCategories([category])
        
        return center
    }()
    
    private func checkAuthorization(){
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                self.notificationsAllowed = true
                self.scheduleNotificationsApproved()
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .denied:
                print("ERROR - Notification Permissions Denied")
                self.notificationsAllowed = false
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .sound]) { didAllow, error in
                    if didAllow {
                        self.notificationsAllowed = true
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                        self.scheduleNotificationsApproved()
                    }
                }
            default:
                return
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Need to send your token to backend
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { print(error.localizedDescription)
    }
    
    
    func scheduleNotifications() {
        print("Scheduling notifications - in handler")
        checkAuthorization()
    }
    
    private func scheduleNotificationsApproved() {
        let content = UNMutableNotificationContent()
        content.title = "Your partner is close"
        content.body = "Your partner is 200 meters away"
        content.sound = .default
        content.categoryIdentifier = notificationIdentifier
        
        notificationCenter.removeAllPendingNotificationRequests()
        
        let calendar = Calendar.current
        for date in self.scheduledNotifications{
            var dateComponents = DateComponents(calendar: calendar, timeZone: .current)
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            
            print("Scheduling notification at \(hour):\(minute)")
            
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            notificationCenter.add(request)
        }
        
        let single = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let requestSingle = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: single)
        notificationCenter.add(requestSingle)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        let id = response.notification.request.identifier
        print("1: Received notification with ID = \(id)")

        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let id = notification.request.identifier
        print("2: Received notification with ID = \(id)")

        completionHandler([.sound, .badge])
        
    }

}
