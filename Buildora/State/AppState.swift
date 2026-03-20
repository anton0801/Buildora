import SwiftUI
import Combine

// MARK: - AppState (Main EnvironmentObject)

final class AppState: ObservableObject {

    // MARK: - Auth State
    @Published var currentUser: User? = nil
    @Published var isAuthenticated: Bool = false
    @Published var selectedProjectId: UUID? = nil

    // MARK: - App Settings (persisted)
    @AppStorage("appTheme")              var theme: String = "system"
    @AppStorage("appCurrency")           var currency: String = "USD"
    @AppStorage("appMeasurementUnit")    var measurementUnit: String = "m"
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("notificationsEnabled")  var notificationsEnabled: Bool = true
    @AppStorage("deadlineNotifications") var deadlineNotifications: Bool = true
    @AppStorage("budgetNotifications")   var budgetNotifications: Bool = true

    private let store = DataStore.shared

    init() {
        restoreSession()
    }

    // MARK: - Session

    func restoreSession() {
        guard let idStr = UserDefaults.standard.string(forKey: "currentUserId"),
              let uuid = UUID(uuidString: idStr),
              let user = store.data.users.first(where: { $0.id == uuid }) else {
            return
        }
        currentUser = user
        isAuthenticated = true

        // Restore last selected project
        if let pIdStr = UserDefaults.standard.string(forKey: "lastProjectId"),
           let pUUID = UUID(uuidString: pIdStr) {
            selectedProjectId = pUUID
        }
    }

    func login(user: User) {
        currentUser = user
        isAuthenticated = true
        UserDefaults.standard.set(user.id.uuidString, forKey: "currentUserId")
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
        selectedProjectId = nil
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        UserDefaults.standard.removeObject(forKey: "lastProjectId")
    }

    func deleteAccount() {
        guard let user = currentUser else { return }
        store.deleteUser(userId: user.id)
        logout()
    }

    // MARK: - Project Selection

    func selectProject(_ projectId: UUID?) {
        selectedProjectId = projectId
        if let pId = projectId {
            UserDefaults.standard.set(pId.uuidString, forKey: "lastProjectId")
        } else {
            UserDefaults.standard.removeObject(forKey: "lastProjectId")
        }
    }

    var selectedProject: Project? {
        guard let pid = selectedProjectId else { return nil }
        return store.data.projects.first(where: { $0.id == pid })
    }

    // MARK: - Theme

    var colorScheme: ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    // MARK: - Currency Symbol

    var currencySymbol: String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "RUB": return "₽"
        case "UAH": return "₴"
        default:    return "$"
        }
    }

    func formatAmount(_ amount: Double) -> String {
        "\(currencySymbol)\(String(format: "%.0f", amount))"
    }

    // MARK: - Notifications

    func toggleNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        if enabled {
            NotificationManager.shared.requestPermission { granted in
                self.notificationsEnabled = granted
            }
        } else {
            NotificationManager.shared.cancelAllNotifications()
        }
    }
}

protocol ApplicationUseCase {
    func initialize()
    func handleTracking(_ data: [String: Any])
    func handleNavigation(_ data: [String: Any])
    func requestPermission()
    func deferPermission()
    func handleNetworkChange(isConnected: Bool)
    func handleTimeout()
}

protocol NotificationPort {
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    func registerForRemoteNotifications()
}

protocol StoragePort {
    func saveTracking(_ data: [String: String])
    func saveNavigation(_ data: [String: String])
    func saveEndpoint(_ url: String)
    func saveMode(_ mode: String)
    func savePermissions(_ state: PermissionState)
    func markLaunched()
    func loadConfig() -> LoadedConfig
}

protocol ValidationPort {
    func validate() async throws -> Bool
}

protocol NetworkPort {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func fetchEndpoint(tracking: [String: Any]) async throws -> String
}


protocol EventPublisher {
    func publish(_ event: DomainEvent)
}
