import Foundation

// MARK: - User

struct User: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var passwordHash: String
    var createdAt: Date = Date()
}

// MARK: - Project

struct Project: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var userId: UUID
    var name: String
    var projectDescription: String = ""
    var status: ProjectStatus = .planning
    var totalBudget: Double = 0
    var startDate: Date? = nil
    var endDate: Date? = nil
    var createdAt: Date = Date()
}

struct TrackingInfo {
    let data: [String: String]
    
    var isEmpty: Bool { data.isEmpty }
    var isOrganic: Bool { data["af_status"] == "Organic" }
    
    static var empty: TrackingInfo {
        TrackingInfo(data: [:])
    }
}



enum ProjectStatus: String, Codable, CaseIterable {
    case planning   = "Planning"
    case active     = "Active"
    case paused     = "Paused"
    case completed  = "Completed"

    var color: String {
        switch self {
        case .planning:  return "3B82F6"
        case .active:    return "52C873"
        case .paused:    return "FF9F43"
        case .completed: return "35D0BA"
        }
    }
}

// MARK: - Room

struct Room: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var projectId: UUID
    var name: String
    var width: Double = 0
    var length: Double = 0
    var height: Double = 2.7
    var stage: RoomStage = .planning
    var notes: String = ""
    var startDate: Date? = nil
    var endDate: Date? = nil
    var createdAt: Date = Date()

    var area: Double { width * length }
    var volume: Double { width * length * height }
}

struct NavigationInfo {
    let data: [String: String]
    
    var isEmpty: Bool { data.isEmpty }
    
    static var empty: NavigationInfo {
        NavigationInfo(data: [:])
    }
}

enum RoomStage: String, Codable, CaseIterable {
    case planning   = "Planning"
    case preparing  = "Preparing"
    case inProgress = "In Progress"
    case finishing  = "Finishing"
    case done       = "Done"

    var progress: Double {
        switch self {
        case .planning:   return 0.1
        case .preparing:  return 0.3
        case .inProgress: return 0.6
        case .finishing:  return 0.85
        case .done:       return 1.0
        }
    }

    var color: String {
        switch self {
        case .planning:   return "3B82F6"
        case .preparing:  return "FF9F43"
        case .inProgress: return "FFC83A"
        case .finishing:  return "35D0BA"
        case .done:       return "52C873"
        }
    }

    var icon: String {
        switch self {
        case .planning:   return "map"
        case .preparing:  return "hammer"
        case .inProgress: return "wrench.and.screwdriver"
        case .finishing:  return "paintbrush"
        case .done:       return "checkmark.seal.fill"
        }
    }
}

struct PermissionState {
    var approved: Bool
    var declined: Bool
    var lastAsked: Date?
    
    var canAsk: Bool {
        guard !approved && !declined else { return false }
        if let date = lastAsked {
            return Date().timeIntervalSince(date) / 86400 >= 3
        }
        return true
    }
    
    static var initial: PermissionState {
        PermissionState(approved: false, declined: false, lastAsked: nil)
    }
}


struct RenovationTask: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var projectId: UUID
    var roomId: UUID? = nil
    var title: String
    var taskDescription: String = ""
    var priority: TaskPriority = .medium
    var status: TaskStatus = .todo
    var dueDate: Date? = nil
    var completedAt: Date? = nil
    var createdAt: Date = Date()

    var isOverdue: Bool {
        guard let due = dueDate, status != .completed else { return false }
        return due < Date()
    }

    var isToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }
}


struct AppConfig {
    var mode: String?
    var firstLaunch: Bool
    
    static var initial: AppConfig {
        AppConfig(mode: nil, firstLaunch: true)
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"
    case urgent = "Urgent"

    var color: String {
        switch self {
        case .low:    return "35D0BA"
        case .medium: return "3B82F6"
        case .high:   return "FF9F43"
        case .urgent: return "FF6B57"
        }
    }

    var icon: String {
        switch self {
        case .low:    return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high:   return "arrow.up.circle"
        case .urgent: return "exclamationmark.circle.fill"
        }
    }
}

enum AppPhase {
    case idle
    case loading
    case validating
    case validated
    case processing
    case ready(String)
    case failed
    case offline
}

enum TaskStatus: String, Codable, CaseIterable {
    case todo       = "To Do"
    case inProgress = "In Progress"
    case completed  = "Completed"

    var color: String {
        switch self {
        case .todo:       return "E9E1D3"
        case .inProgress: return "FFC83A"
        case .completed:  return "52C873"
        }
    }
}

enum DomainEvent {
    case trackingDataChanged(TrackingInfo)
    case navigationDataChanged(NavigationInfo)
    case validationCompleted(Bool)
    case endpointReceived(String)
    case permissionStateChanged(PermissionState)
    case phaseChanged(AppPhase)
    case shouldNavigateToMain
    case shouldNavigateToWeb
    case shouldShowPermissionPrompt
    case shouldHidePermissionPrompt
    case networkStatusChanged(Bool)
}

struct Material: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var projectId: UUID
    var roomId: UUID? = nil
    var name: String
    var category: MaterialCategory = .other
    var quantity: Double = 1
    var unit: String = "pcs"
    var pricePerUnit: Double = 0
    var supplier: String = ""
    var notes: String = ""
    var inStock: Bool = false
    var createdAt: Date = Date()

    var totalCost: Double { quantity * pricePerUnit }
}

enum MaterialCategory: String, Codable, CaseIterable {
    case paint       = "Paint"
    case flooring    = "Flooring"
    case tiles       = "Tiles"
    case lighting    = "Lighting"
    case plumbing    = "Plumbing"
    case hardware    = "Hardware"
    case decor       = "Decor"
    case tools       = "Tools"
    case electrical  = "Electrical"
    case other       = "Other"

    var icon: String {
        switch self {
        case .paint:      return "paintbrush"
        case .flooring:   return "square.grid.3x3"
        case .tiles:      return "square.on.square"
        case .lighting:   return "lightbulb"
        case .plumbing:   return "drop"
        case .hardware:   return "wrench"
        case .decor:      return "star"
        case .tools:      return "hammer"
        case .electrical: return "bolt"
        case .other:      return "cube.box"
        }
    }

    var color: String {
        switch self {
        case .paint:      return "FF6B57"
        case .flooring:   return "FF9F43"
        case .tiles:      return "FFC83A"
        case .lighting:   return "35D0BA"
        case .plumbing:   return "3B82F6"
        case .hardware:   return "52C873"
        case .decor:      return "FF9F43"
        case .tools:      return "FF6B57"
        case .electrical: return "FFC83A"
        case .other:      return "E9E1D3"
        }
    }
}

struct LoadedConfig {
    var mode: String?
    var firstLaunch: Bool
    var tracking: [String: String]
    var navigation: [String: String]
    var permissions: LoadedPermissions
    
    struct LoadedPermissions {
        var approved: Bool
        var declined: Bool
        var lastAsked: Date?
    }
}

struct ShoppingItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var projectId: UUID
    var name: String
    var category: ShoppingCategory = .later
    var quantity: Double = 1
    var unit: String = "pcs"
    var estimatedPrice: Double = 0
    var actualPrice: Double? = nil
    var store: String = ""
    var notes: String = ""
    var bought: Bool = false
    var createdAt: Date = Date()
}

enum ShoppingCategory: String, Codable, CaseIterable {
    case urgent   = "Urgent"
    case thisWeek = "This Week"
    case later    = "Later"
    case bought   = "Bought"

    var color: String {
        switch self {
        case .urgent:   return "FF6B57"
        case .thisWeek: return "FF9F43"
        case .later:    return "3B82F6"
        case .bought:   return "52C873"
        }
    }

    var icon: String {
        switch self {
        case .urgent:   return "exclamationmark.triangle"
        case .thisWeek: return "calendar"
        case .later:    return "clock"
        case .bought:   return "checkmark.circle"
        }
    }
}

// MARK: - Budget Expense

struct BudgetExpense: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var projectId: UUID
    var category: ExpenseCategory = .other
    var amount: Double
    var expenseDescription: String = ""
    var date: Date = Date()
    var isUnexpected: Bool = false
    var createdAt: Date = Date()
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case materials  = "Materials"
    case labor      = "Labor"
    case delivery   = "Delivery"
    case furniture  = "Furniture"
    case decor      = "Decor"
    case tools      = "Tools"
    case other      = "Other"

    var icon: String {
        switch self {
        case .materials:  return "cube.box"
        case .labor:      return "person.2"
        case .delivery:   return "shippingbox"
        case .furniture:  return "chair"
        case .decor:      return "star"
        case .tools:      return "hammer"
        case .other:      return "ellipsis.circle"
        }
    }

    var color: String {
        switch self {
        case .materials:  return "3B82F6"
        case .labor:      return "FF9F43"
        case .delivery:   return "35D0BA"
        case .furniture:  return "FFC83A"
        case .decor:      return "FF6B57"
        case .tools:      return "52C873"
        case .other:      return "E9E1D3"
        }
    }
}

// MARK: - Room Measurement

struct RoomMeasurement: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var roomId: UUID
    var projectId: UUID
    var type: MeasurementType = .wall
    var name: String
    var width: Double = 0
    var height: Double = 0
    var unit: MeasurementUnit = .meters
    var notes: String = ""
    var createdAt: Date = Date()

    var area: Double { width * height }
}

enum MeasurementType: String, Codable, CaseIterable {
    case wall    = "Wall"
    case ceiling = "Ceiling"
    case floor   = "Floor"
    case window  = "Window"
    case door    = "Door"

    var icon: String {
        switch self {
        case .wall:    return "rectangle.portrait"
        case .ceiling: return "arrow.up.square"
        case .floor:   return "arrow.down.square"
        case .window:  return "window.vertical.open"
        case .door:    return "door.right.hand.open"
        }
    }
}

enum MeasurementUnit: String, Codable, CaseIterable {
    case meters      = "m"
    case centimeters = "cm"
    case feet        = "ft"
    case inches      = "in"
}

// MARK: - Progress Photo

struct ProgressPhoto: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var projectId: UUID
    var roomId: UUID? = nil
    var phase: PhotoPhase = .during
    var title: String
    var notes: String = ""
    var imagePath: String? = nil
    var createdAt: Date = Date()
}

enum PhotoPhase: String, Codable, CaseIterable {
    case before = "Before"
    case during = "During"
    case after  = "After"

    var color: String {
        switch self {
        case .before: return "FF6B57"
        case .during: return "FFC83A"
        case .after:  return "52C873"
        }
    }

    var icon: String {
        switch self {
        case .before: return "clock.arrow.circlepath"
        case .during: return "hammer.circle"
        case .after:  return "sparkles"
        }
    }
}

// MARK: - Contact

struct Contact: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var userId: UUID
    var projectId: UUID? = nil
    var name: String
    var role: ContactRole = .other
    var phone: String = ""
    var email: String = ""
    var notes: String = ""
    var rating: Int = 0
    var createdAt: Date = Date()
}

// MARK: - Job Log Entry

struct JobLogEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var contactId: UUID
    var date: Date = Date()
    var tasksDone: String = ""
    var hoursWorked: Double = 0
    var amountPaid: Double = 0
    var roomId: UUID? = nil
    var notes: String = ""
    var imagePath: String? = nil
    var createdAt: Date = Date()
}

enum ContactRole: String, Codable, CaseIterable {
    case master      = "Master"
    case electrician = "Electrician"
    case plumber     = "Plumber"
    case delivery    = "Delivery"
    case store       = "Store"
    case other       = "Other"

    var icon: String {
        switch self {
        case .master:      return "hammer.fill"
        case .electrician: return "bolt.fill"
        case .plumber:     return "drop.fill"
        case .delivery:    return "shippingbox.fill"
        case .store:       return "bag.fill"
        case .other:       return "person.fill"
        }
    }

    var color: String {
        switch self {
        case .master:      return "FF9F43"
        case .electrician: return "FFC83A"
        case .plumber:     return "3B82F6"
        case .delivery:    return "35D0BA"
        case .store:       return "52C873"
        case .other:       return "E9E1D3"
        }
    }
}

// MARK: - App Data Container

struct AppData: Codable {
    var users: [User] = []
    var projects: [Project] = []
    var rooms: [Room] = []
    var tasks: [RenovationTask] = []
    var materials: [Material] = []
    var shoppingItems: [ShoppingItem] = []
    var expenses: [BudgetExpense] = []
    var measurements: [RoomMeasurement] = []
    var photos: [ProgressPhoto] = []
    var contacts: [Contact] = []
    var jobLogEntries: [JobLogEntry] = []
}
