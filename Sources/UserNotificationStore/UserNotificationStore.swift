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
    func requestNotification(at date:Date, title: String, body: String, categoryIdentifier: String?) async
    func cancelNotification() async
    // for unit testing
    var requestNum: Int { get async }
}

public final actor DummyUserNotificationStore: UserNotificationStoreProtocol {
    public var requestNum:Int = 0

    public init() {}
    public func requestAuthorization(options:UNAuthorizationOptions) async throws -> Bool {
        // always OK
        return true
    }
    public func requestNotification(at date:Date, title: String, body: String, categoryIdentifier: String?) async {
        // record request
        requestNum += 1
    }
    public func cancelNotification() async {
        // clear num of requests
        requestNum = 0
    }
}

public final actor UserNotificationStore: UserNotificationStoreProtocol {
    var myNotificationIDs: Array<String> = Array()

    public init() {}
    
    public func requestAuthorization(options:UNAuthorizationOptions = []) async throws -> Bool {
        let result = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        return result
    }
    
    public func requestNotification(at date:Date, title: String, body: String, categoryIdentifier: String? = nil) async {
        let center = UNUserNotificationCenter.current()
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard (settings.authorizationStatus == .authorized) ||
                (settings.authorizationStatus == .provisional) else { return }
        await self.cancelNotification()
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
            
            do {
                try await center.add(request)
            } catch {
                print("Error in request with \(error)")
            }
        }
    }
    
    public func cancelNotification() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: myNotificationIDs)
        myNotificationIDs.removeAll()
    }
    
    public var requestNum: Int {
        get async {
            return myNotificationIDs.count
        }
    }
}
