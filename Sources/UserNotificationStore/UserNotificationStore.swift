//
//  UserNotificationStore.swift
//
//  Created by : Tomoaki Yagishita on 2022/02/02
//  © 2022  SmallDeskSoftware
//

import Foundation
import UserNotifications

public protocol UserNotificationStoreProtocol: ObservableObject {
    init()
    func requestAuthorization(options:UNAuthorizationOptions) async throws -> Bool
    func requestNotification(at date:Date, title: String, body: String, categoryIdentifier: String?)
    func cancelNotification()
    // for unit testing
    var requestNum: Int { get }
}

public final class DummyUserNotificationStore: UserNotificationStoreProtocol {
    public var requestNum:Int = 0

    public required init() {}
    public func requestAuthorization(options:UNAuthorizationOptions) async throws -> Bool {
        // always OK
        return true
    }
    public func requestNotification(at date:Date, title: String, body: String, categoryIdentifier: String?) {
        // record request
        requestNum += 1
    }
    public func cancelNotification() {
        // clear num of requests
        requestNum = 0
    }
}

public final class UserNotificationStore: UserNotificationStoreProtocol {
    var myNotificationIDs: Array<String> = Array()

    public init() {}
    
    public func requestAuthorization(options:UNAuthorizationOptions = []) async throws -> Bool {
        let result = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        return result
    }
    
    public func requestNotification(at date:Date, title: String, body: String, categoryIdentifier: String? = nil) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard (settings.authorizationStatus == .authorized) ||
                    (settings.authorizationStatus == .provisional) else { return }
            self.cancelNotification()
            if settings.alertSetting == .enabled {
                // schedule alert
                let notificationContent = UNMutableNotificationContent()
                notificationContent.title = title //"Pomodoro !"
                notificationContent.body = body
                
                if let categoryIdentifier = categoryIdentifier {
                    notificationContent.categoryIdentifier = categoryIdentifier
                }
                
                if settings.soundSetting == .enabled {
                    notificationContent.sound = UNNotificationSound.default
                }
                // can set badge info with checking settings.badgeSetting

                let dateComp = Calendar.current.dateComponents(in: .current, from: date)
                var dc = DateComponents()
                dc.hour = dateComp.hour
                dc.minute = dateComp.minute
                dc.second = dateComp.second
                
                //print("trigger at \(dc)")
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
                
                let id = UUID().uuidString
                self.myNotificationIDs.append(id)
                
                let request = UNNotificationRequest(identifier: id, content: notificationContent, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("Error in request with \(error)")
                    }
                }
            }
        }
    }
    
    public func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: myNotificationIDs)
        myNotificationIDs.removeAll()
    }
    
    public var requestNum: Int {
        return myNotificationIDs.count
    }
}
