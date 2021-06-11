//
//  LocalNotificationManager.swift
//  Events
//
//  Created by Elliott Harris on 6/11/21.
//

import UIKit
import UserNotifications
import RealmSwift

class LocalNotificationManager {
    struct Notification {
        var id: String
        var title: String
        var name: String
        var datetime: DateComponents
    }
    
    var notifications: [Notification] = []
    let notificationCenter = UNUserNotificationCenter.current()
    
    func listScheduledNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            requests.forEach { request in
                print(request)
            }
        }
    }
    
    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            guard error == nil else {
                completion(false)
                return
            }
            
            completion(granted)
        }
    }
    
    func schedule() {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization { granted in
                    if granted {
                        self.scheduleNotifications()
                    }
                }
            case .authorized, .provisional:
                self.scheduleNotifications()
            default:
                break
            }
        }
    }
    
    private func scheduleNotifications() {
        notifications.forEach { notification in
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.sound = .default
            content.userInfo = ["name": notification.name]
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: notification.datetime, repeats: false)
            let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                guard error == nil else { return }
                
                print("Notification with id \(notification.id) scheduled")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let rootViewController = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else {
                return
            }

        if let eventVC = storyboard.instantiateViewController(withIdentifier: "EventsViewController") as? EventsViewController,
           let contactVC = rootViewController as? UINavigationController, let realm = try? Realm() {

            let contacts = realm.objects(Contact.self)
            let contact = contacts.first { contact in
                let name = contact.name
                print(name)
                let notiName = response.notification.request.content.userInfo["name"] as! String
                print(notiName)
                return name == notiName
            }

            if let contact = contact {
                eventVC.contact = contact
                contactVC.pushViewController(eventVC, animated: true)
            }

        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let id = notification.request.identifier

        print("Received notification with id \(id)")

        completionHandler([.sound, .banner])
    }
}
