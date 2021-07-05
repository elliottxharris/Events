//
//  LocalNotificationManager.swift
//  Events
//
//  Created by Elliott Harris on 6/11/21.
//

import UIKit
import UserNotifications
import CoreData

class LocalNotificationManager {
    struct Notification {
        var id: String
        var title: String
        var name: String
        var datetime: DateComponents
    }
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    func removeScheduledNotification(id: String) {
        notificationCenter.getPendingNotificationRequests { (notificationRequests) in
             for notificationRequest: UNNotificationRequest in notificationRequests {
                if notificationRequest.identifier == id {
                    self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
                    print("Removed notification with id: \(id)")
                    break
                }
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
    
    func schedule(notification: Notification?) {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization { granted in
                    if granted {
                        self.scheduleNotification(notification: notification)
                    }
                }
            case .authorized, .provisional:
                self.scheduleNotification(notification: notification)
            default:
                break
            }
        }
    }
    
    private func scheduleNotification(notification: Notification?) {
        if let notification = notification {
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
           let contactVC = rootViewController as? UINavigationController {

            let fetchRequest = NSFetchRequest<Contact>(entityName: "Contact")
            do {
                let contacts: [Contact] = try persistentContainer.viewContext.fetch(fetchRequest)
                let contact = contacts.first { contact in
                    contact.name == response.notification.request.content.userInfo["name"] as? String
                }

                if let contact = contact {
                    eventVC.contact = contact
                    contactVC.pushViewController(eventVC, animated: true)
                }

            } catch {
                print("Could not fetch contacts")
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
