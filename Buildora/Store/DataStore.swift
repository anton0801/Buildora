import Foundation
import CryptoKit

// MARK: - DataStore

final class DataStore {
    static let shared = DataStore()
    private let dataKey = "buildora_app_data"
    private(set) var data: AppData = AppData()

    private init() { load() }

    // MARK: - Persistence

    func load() {
        guard let raw = UserDefaults.standard.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(AppData.self, from: raw) else {
            return
        }
        data = decoded
    }

    func save() {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: dataKey)
    }

    func clearAll() {
        data = AppData()
        UserDefaults.standard.removeObject(forKey: dataKey)
        UserDefaults.standard.removeObject(forKey: "currentUserId")
    }

    // MARK: - Auth

    func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func registerUser(name: String, email: String, password: String) -> Result<User, AuthError> {
        let emailLower = email.lowercased().trimmingCharacters(in: .whitespaces)
        if data.users.contains(where: { $0.email.lowercased() == emailLower }) {
            return .failure(.emailInUse)
        }
        let user = User(name: name, email: emailLower, passwordHash: hashPassword(password))
        data.users.append(user)
        save()
        return .success(user)
    }

    func loginUser(email: String, password: String) -> Result<User, AuthError> {
        let emailLower = email.lowercased().trimmingCharacters(in: .whitespaces)
        let hash = hashPassword(password)
        guard let user = data.users.first(where: { $0.email.lowercased() == emailLower && $0.passwordHash == hash }) else {
            return .failure(.invalidCredentials)
        }
        return .success(user)
    }

    func deleteUser(userId: UUID) {
        data.users.removeAll { $0.id == userId }
        data.projects.removeAll { $0.userId == userId }
        // Clean up orphaned data
        let projectIds = Set(data.projects.map { $0.id })
        data.rooms.removeAll { !projectIds.contains($0.projectId) }
        data.tasks.removeAll { !projectIds.contains($0.projectId) }
        data.materials.removeAll { !projectIds.contains($0.projectId) }
        data.shoppingItems.removeAll { !projectIds.contains($0.projectId) }
        data.expenses.removeAll { !projectIds.contains($0.projectId) }
        data.measurements.removeAll { m in
            !data.rooms.contains(where: { $0.id == m.roomId })
        }
        data.photos.removeAll { !projectIds.contains($0.projectId) }
        data.contacts.removeAll { $0.userId == userId }
        save()
    }

    // MARK: - Projects

    func projects(for userId: UUID) -> [Project] {
        data.projects.filter { $0.userId == userId }.sorted { $0.createdAt > $1.createdAt }
    }

    func addProject(_ project: Project) {
        data.projects.append(project)
        save()
    }

    func updateProject(_ project: Project) {
        if let idx = data.projects.firstIndex(where: { $0.id == project.id }) {
            data.projects[idx] = project
            save()
        }
    }

    func deleteProject(_ project: Project) {
        data.projects.removeAll { $0.id == project.id }
        let pId = project.id
        data.rooms.removeAll { $0.projectId == pId }
        data.tasks.removeAll { $0.projectId == pId }
        data.materials.removeAll { $0.projectId == pId }
        data.shoppingItems.removeAll { $0.projectId == pId }
        data.expenses.removeAll { $0.projectId == pId }
        data.photos.removeAll { $0.projectId == pId }
        save()
    }

    // MARK: - Rooms

    func rooms(for projectId: UUID) -> [Room] {
        data.rooms.filter { $0.projectId == projectId }.sorted { $0.createdAt > $1.createdAt }
    }

    func addRoom(_ room: Room) {
        data.rooms.append(room)
        save()
    }

    func updateRoom(_ room: Room) {
        if let idx = data.rooms.firstIndex(where: { $0.id == room.id }) {
            data.rooms[idx] = room
            save()
        }
    }

    func deleteRoom(_ room: Room) {
        data.rooms.removeAll { $0.id == room.id }
        data.tasks.removeAll { $0.roomId == room.id }
        data.materials.removeAll { $0.roomId == room.id }
        data.measurements.removeAll { $0.roomId == room.id }
        data.photos.removeAll { $0.roomId == room.id }
        save()
    }

    // MARK: - Tasks

    func tasks(for projectId: UUID) -> [RenovationTask] {
        data.tasks.filter { $0.projectId == projectId }.sorted { $0.createdAt > $1.createdAt }
    }

    func allTasks(for userId: UUID) -> [RenovationTask] {
        let pIds = Set(projects(for: userId).map { $0.id })
        return data.tasks.filter { pIds.contains($0.projectId) }.sorted { $0.createdAt > $1.createdAt }
    }

    func addTask(_ task: RenovationTask) {
        data.tasks.append(task)
        save()
    }

    func updateTask(_ task: RenovationTask) {
        if let idx = data.tasks.firstIndex(where: { $0.id == task.id }) {
            data.tasks[idx] = task
            save()
        }
    }

    func deleteTask(_ task: RenovationTask) {
        data.tasks.removeAll { $0.id == task.id }
        save()
    }

    // MARK: - Materials

    func materials(for projectId: UUID) -> [Material] {
        data.materials.filter { $0.projectId == projectId }.sorted { $0.createdAt > $1.createdAt }
    }

    func addMaterial(_ material: Material) {
        data.materials.append(material)
        save()
    }

    func updateMaterial(_ material: Material) {
        if let idx = data.materials.firstIndex(where: { $0.id == material.id }) {
            data.materials[idx] = material
            save()
        }
    }

    func deleteMaterial(_ material: Material) {
        data.materials.removeAll { $0.id == material.id }
        save()
    }

    // MARK: - Shopping

    func shoppingItems(for projectId: UUID) -> [ShoppingItem] {
        data.shoppingItems.filter { $0.projectId == projectId }.sorted { $0.createdAt > $1.createdAt }
    }

    func addShoppingItem(_ item: ShoppingItem) {
        data.shoppingItems.append(item)
        save()
    }

    func updateShoppingItem(_ item: ShoppingItem) {
        if let idx = data.shoppingItems.firstIndex(where: { $0.id == item.id }) {
            data.shoppingItems[idx] = item
            save()
        }
    }

    func deleteShoppingItem(_ item: ShoppingItem) {
        data.shoppingItems.removeAll { $0.id == item.id }
        save()
    }

    // MARK: - Budget

    func expenses(for projectId: UUID) -> [BudgetExpense] {
        data.expenses.filter { $0.projectId == projectId }.sorted { $0.date > $1.date }
    }

    func addExpense(_ expense: BudgetExpense) {
        data.expenses.append(expense)
        save()
    }

    func updateExpense(_ expense: BudgetExpense) {
        if let idx = data.expenses.firstIndex(where: { $0.id == expense.id }) {
            data.expenses[idx] = expense
            save()
        }
    }

    func deleteExpense(_ expense: BudgetExpense) {
        data.expenses.removeAll { $0.id == expense.id }
        save()
    }

    func totalSpent(for projectId: UUID) -> Double {
        expenses(for: projectId).reduce(0) { $0 + $1.amount }
    }

    func measurements(for projectId: UUID) -> [RoomMeasurement] {
        let roomIds = Set(rooms(for: projectId).map { $0.id })
        return data.measurements.filter { roomIds.contains($0.roomId) }.sorted { $0.createdAt > $1.createdAt }
    }

    func measurements(to roomId: UUID) -> [RoomMeasurement] {
        data.measurements.filter { $0.roomId == roomId }.sorted { $0.createdAt > $1.createdAt }
    }

    func addMeasurement(_ m: RoomMeasurement) {
        data.measurements.append(m)
        save()
    }

    func updateMeasurement(_ m: RoomMeasurement) {
        if let idx = data.measurements.firstIndex(where: { $0.id == m.id }) {
            data.measurements[idx] = m
            save()
        }
    }

    func deleteMeasurement(_ m: RoomMeasurement) {
        data.measurements.removeAll { $0.id == m.id }
        save()
    }

    // MARK: - Photos

    func photos(for projectId: UUID) -> [ProgressPhoto] {
        data.photos.filter { $0.projectId == projectId }.sorted { $0.createdAt > $1.createdAt }
    }

    func addPhoto(_ photo: ProgressPhoto) {
        data.photos.append(photo)
        save()
    }

    func updatePhoto(_ photo: ProgressPhoto) {
        if let idx = data.photos.firstIndex(where: { $0.id == photo.id }) {
            data.photos[idx] = photo
            save()
        }
    }

    func deletePhoto(_ photo: ProgressPhoto) {
        // Delete image file if exists
        if let path = photo.imagePath {
            try? FileManager.default.removeItem(atPath: path)
        }
        data.photos.removeAll { $0.id == photo.id }
        save()
    }

    // MARK: - Contacts

    func contacts(for userId: UUID) -> [Contact] {
        data.contacts.filter { $0.userId == userId }.sorted { $0.createdAt > $1.createdAt }
    }

    func addContact(_ contact: Contact) {
        data.contacts.append(contact)
        save()
    }

    func updateContact(_ contact: Contact) {
        if let idx = data.contacts.firstIndex(where: { $0.id == contact.id }) {
            data.contacts[idx] = contact
            save()
        }
    }

    func deleteContact(_ contact: Contact) {
        data.contacts.removeAll { $0.id == contact.id }
        save()
    }

    // MARK: - Image Storage

    func saveImage(_ data: Data, for photoId: UUID) -> String? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent("\(photoId.uuidString).jpg")
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
    }

    func loadImage(from path: String) -> Data? {
        try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    // MARK: - Statistics

    func completedTasksCount(for projectId: UUID) -> Int {
        tasks(for: projectId).filter { $0.status == .completed }.count
    }

    func totalTasksCount(for projectId: UUID) -> Int {
        tasks(for: projectId).count
    }

    func overallProgress(for projectId: UUID) -> Double {
        let total = totalTasksCount(for: projectId)
        guard total > 0 else { return 0 }
        return Double(completedTasksCount(for: projectId)) / Double(total)
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case emailInUse
    case invalidCredentials
    case weakPassword
    case invalidEmail

    var errorDescription: String? {
        switch self {
        case .emailInUse:         return "This email is already registered."
        case .invalidCredentials: return "Invalid email or password."
        case .weakPassword:       return "Password must be at least 6 characters."
        case .invalidEmail:       return "Please enter a valid email address."
        }
    }
}
