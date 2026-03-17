import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func checkPermission(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    // MARK: - Schedule Task Deadline Notification

    func scheduleTaskDeadline(task: RenovationTask) {
        guard let dueDate = task.dueDate else { return }

        // Notify 1 day before
        let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Due Tomorrow"
        content.body = "\"\(task.title)\" is due tomorrow!"
        content.sound = .default
        content.badge = 1

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "task_\(task.id.uuidString)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelTaskNotification(taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task_\(taskId.uuidString)"])
    }

    // MARK: - Schedule Budget Alert

    func scheduleBudgetExceeded(projectName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Budget Exceeded!"
        content.body = "Project \"\(projectName)\" has exceeded its budget."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "budget_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Delivery Reminder

    func scheduleDeliveryReminder(title: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Delivery Today"
        content.body = "Your delivery \"\(title)\" is expected today."
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "delivery_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel All

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: - Cancel by prefix

    func cancelNotifications(withPrefix prefix: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
