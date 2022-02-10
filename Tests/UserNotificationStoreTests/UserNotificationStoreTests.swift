import XCTest
@testable import UserNotificationStore

final class UserNotificationStoreTests: XCTestCase {
    func test_UserNotifiacationStore_request() throws {
        let sut = DummyUserNotificationStore()
        XCTAssertNotNil(sut)
        
        // initially requested notification is zero
        XCTAssertEqual(sut.requestNum, 0)

        // request
        sut.requestNotification(at: Date().advanced(by: 60*50), title: "New Notification", body: "notification body", categoryIdentifier: nil)
        XCTAssertEqual(sut.requestNum, 1)

        // cancel
        sut.cancelNotification()
        XCTAssertEqual(sut.requestNum, 0)
    }
}
