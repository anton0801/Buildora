import SwiftUI
import Combine

// MARK: - Main Data ViewModel

final class DataViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var rooms: [Room] = []
    @Published var tasks: [RenovationTask] = []
    @Published var materials: [Material] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var expenses: [BudgetExpense] = []
    @Published var measurements: [RoomMeasurement] = []
    @Published var photos: [ProgressPhoto] = []
    @Published var contacts: [Contact] = []
    @Published var jobLogEntries: [JobLogEntry] = []

    private let store = DataStore.shared
    private var userId: UUID?
    private var projectId: UUID?

    // MARK: - Load

    func load(userId: UUID, projectId: UUID? = nil) {
        self.userId = userId
        self.projectId = projectId
        reload()
    }

    func reload() {
        guard let uid = userId else { return }
        projects = store.projects(for: uid)
        contacts = store.contacts(for: uid)
        let contactIds = Set(contacts.map { $0.id })
        jobLogEntries = store.data.jobLogEntries.filter { contactIds.contains($0.contactId) }

        if let pid = projectId {
            reloadProject(pid)
        } else if let pid = projects.first?.id {
            reloadProject(pid)
        }
    }

    func reloadProject(_ projectId: UUID) {
        self.projectId = projectId
        rooms      = store.rooms(for: projectId)
        tasks      = store.tasks(for: projectId)
        materials  = store.materials(for: projectId)
        shoppingItems = store.shoppingItems(for: projectId)
        expenses   = store.expenses(for: projectId)
        photos     = store.photos(for: projectId)
        measurements = store.measurements(for: projectId)
    }

    // MARK: - Projects

    func addProject(name: String, description: String, budget: Double, startDate: Date?, endDate: Date?) {
        guard let uid = userId else { return }
        let project = Project(userId: uid, name: name, projectDescription: description, totalBudget: budget, startDate: startDate, endDate: endDate)
        store.addProject(project)
        reload()
    }

    func updateProject(_ project: Project) {
        store.updateProject(project)
        reload()
    }

    func deleteProject(_ project: Project) {
        store.deleteProject(project)
        if projectId == project.id { projectId = nil }
        reload()
    }

    // MARK: - Rooms

    func addRoom(name: String, width: Double, length: Double, height: Double, stage: RoomStage, notes: String) {
        guard let pid = projectId else { return }
        let room = Room(projectId: pid, name: name, width: width, length: length, height: height, stage: stage, notes: notes)
        store.addRoom(room)
        rooms = store.rooms(for: pid)
    }

    func updateRoom(_ room: Room) {
        store.updateRoom(room)
        if let pid = projectId { rooms = store.rooms(for: pid) }
    }

    func deleteRoom(_ room: Room) {
        store.deleteRoom(room)
        if let pid = projectId {
            rooms = store.rooms(for: pid)
            tasks = store.tasks(for: pid)
            materials = store.materials(for: pid)
            measurements = store.measurements(for: pid)
        }
    }

    // MARK: - Tasks

    func addTask(title: String, description: String, priority: TaskPriority, dueDate: Date?, roomId: UUID?) {
        guard let pid = projectId else { return }
        var task = RenovationTask(projectId: pid, title: title, taskDescription: description, priority: priority)
        task.dueDate = dueDate
        task.roomId = roomId
        store.addTask(task)
        if let pid = projectId { tasks = store.tasks(for: pid) }
        // Schedule notification
        NotificationManager.shared.scheduleTaskDeadline(task: task)
    }

    func updateTask(_ task: RenovationTask) {
        store.updateTask(task)
        if let pid = projectId { tasks = store.tasks(for: pid) }
        NotificationManager.shared.cancelTaskNotification(taskId: task.id)
        NotificationManager.shared.scheduleTaskDeadline(task: task)
    }

    func toggleTaskComplete(_ task: RenovationTask) {
        var updated = task
        if task.status == .completed {
            updated.status = .todo
            updated.completedAt = nil
        } else {
            updated.status = .completed
            updated.completedAt = Date()
        }
        store.updateTask(updated)
        if let pid = projectId { tasks = store.tasks(for: pid) }
    }

    func deleteTask(_ task: RenovationTask) {
        NotificationManager.shared.cancelTaskNotification(taskId: task.id)
        store.deleteTask(task)
        if let pid = projectId { tasks = store.tasks(for: pid) }
    }

    // MARK: - Materials

    func addMaterial(name: String, category: MaterialCategory, quantity: Double, unit: String, price: Double, supplier: String, notes: String, roomId: UUID?) {
        guard let pid = projectId else { return }
        let material = Material(projectId: pid, roomId: roomId, name: name, category: category, quantity: quantity, unit: unit, pricePerUnit: price, supplier: supplier, notes: notes)
        store.addMaterial(material)
        if let pid = projectId { materials = store.materials(for: pid) }
    }

    func updateMaterial(_ material: Material) {
        store.updateMaterial(material)
        if let pid = projectId { materials = store.materials(for: pid) }
    }

    func toggleMaterialStock(_ material: Material) {
        var updated = material
        updated.inStock = !material.inStock
        store.updateMaterial(updated)
        if let pid = projectId { materials = store.materials(for: pid) }
    }

    func deleteMaterial(_ material: Material) {
        store.deleteMaterial(material)
        if let pid = projectId { materials = store.materials(for: pid) }
    }

    // MARK: - Shopping

    func addShoppingItem(name: String, category: ShoppingCategory, quantity: Double, unit: String, price: Double, store storeStr: String, notes: String) {
        guard let pid = projectId else { return }
        let item = ShoppingItem(projectId: pid, name: name, category: category, quantity: quantity, unit: unit, estimatedPrice: price, store: storeStr, notes: notes)
        store.addShoppingItem(item)
        if let pid = projectId { shoppingItems = store.shoppingItems(for: pid) }
    }

    func toggleItemBought(_ item: ShoppingItem) {
        var updated = item
        updated.bought = !item.bought
        updated.category = updated.bought ? .bought : .later
        store.updateShoppingItem(updated)
        if let pid = projectId { shoppingItems = store.shoppingItems(for: pid) }
    }

    func updateShoppingItem(_ item: ShoppingItem) {
        store.updateShoppingItem(item)
        if let pid = projectId { shoppingItems = store.shoppingItems(for: pid) }
    }

    func deleteShoppingItem(_ item: ShoppingItem) {
        store.deleteShoppingItem(item)
        if let pid = projectId { shoppingItems = store.shoppingItems(for: pid) }
    }

    // MARK: - Budget

    func addExpense(category: ExpenseCategory, amount: Double, description: String, date: Date, isUnexpected: Bool) {
        guard let pid = projectId else { return }
        let expense = BudgetExpense(projectId: pid, category: category, amount: amount, expenseDescription: description, date: date, isUnexpected: isUnexpected)
        store.addExpense(expense)
        if let pid = projectId { expenses = store.expenses(for: pid) }

        // Check budget
        if let project = projects.first(where: { $0.id == pid }) {
            if totalSpent > project.totalBudget && project.totalBudget > 0 {
                NotificationManager.shared.scheduleBudgetExceeded(projectName: project.name)
            }
        }
    }

    func updateExpense(_ expense: BudgetExpense) {
        store.updateExpense(expense)
        if let pid = projectId { expenses = store.expenses(for: pid) }
    }

    func deleteExpense(_ expense: BudgetExpense) {
        store.deleteExpense(expense)
        if let pid = projectId { expenses = store.expenses(for: pid) }
    }

    var totalSpent: Double { expenses.reduce(0) { $0 + $1.amount } }
    var totalBudget: Double { projects.first(where: { $0.id == projectId })?.totalBudget ?? 0 }
    var remainingBudget: Double { totalBudget - totalSpent }
    var unexpectedCosts: Double { expenses.filter { $0.isUnexpected }.reduce(0) { $0 + $1.amount } }
    var plannedCosts: Double { expenses.filter { !$0.isUnexpected }.reduce(0) { $0 + $1.amount } }
    var budgetProgress: Double { totalBudget > 0 ? min(totalSpent / totalBudget, 1.0) : 0 }

    func spentByCategory() -> [(ExpenseCategory, Double)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return ExpenseCategory.allCases.compactMap { cat in
            let total = grouped[cat]?.reduce(0) { $0 + $1.amount } ?? 0
            return total > 0 ? (cat, total) : nil
        }.sorted { $0.1 > $1.1 }
    }

    // MARK: - Measurements

    func addMeasurement(roomId: UUID, type: MeasurementType, name: String, width: Double, height: Double, unit: MeasurementUnit, notes: String) {
        guard let pid = projectId else { return }
        let m = RoomMeasurement(roomId: roomId, projectId: pid, type: type, name: name, width: width, height: height, unit: unit, notes: notes)
        store.addMeasurement(m)
        if let pid = projectId { measurements = store.measurements(for: pid) }
    }

    func updateMeasurement(_ m: RoomMeasurement) {
        store.updateMeasurement(m)
        if let pid = projectId { measurements = store.measurements(for: pid) }
    }

    func deleteMeasurement(_ m: RoomMeasurement) {
        store.deleteMeasurement(m)
        if let pid = projectId { measurements = store.measurements(for: pid) }
    }

    func measurements(for roomId: UUID) -> [RoomMeasurement] {
        measurements.filter { $0.roomId == roomId }
    }

    // MARK: - Photos

    func addPhoto(roomId: UUID?, phase: PhotoPhase, title: String, notes: String, imageData: Data?) {
        guard let pid = projectId else { return }
        var photo = ProgressPhoto(projectId: pid, roomId: roomId, phase: phase, title: title, notes: notes)
        if let data = imageData {
            photo.imagePath = store.saveImage(data, for: photo.id)
        }
        store.addPhoto(photo)
        if let pid = projectId { photos = store.photos(for: pid) }
    }

    func deletePhoto(_ photo: ProgressPhoto) {
        store.deletePhoto(photo)
        if let pid = projectId { photos = store.photos(for: pid) }
    }

    // MARK: - Contacts

    func addContact(name: String, role: ContactRole, phone: String, email: String, notes: String) {
        guard let uid = userId else { return }
        let contact = Contact(userId: uid, projectId: projectId, name: name, role: role, phone: phone, email: email, notes: notes)
        store.addContact(contact)
        if let uid = userId { contacts = store.contacts(for: uid) }
    }

    func updateContact(_ contact: Contact) {
        store.updateContact(contact)
        if let uid = userId { contacts = store.contacts(for: uid) }
    }

    func deleteContact(_ contact: Contact) {
        store.deleteContact(contact)
        if let uid = userId { contacts = store.contacts(for: uid) }
    }

    // MARK: - Job Log Entries

    func jobLogEntries(for contactId: UUID) -> [JobLogEntry] {
        jobLogEntries.filter { $0.contactId == contactId }.sorted { $0.date > $1.date }
    }

    func addJobLogEntry(contactId: UUID, date: Date, tasksDone: String, hoursWorked: Double, amountPaid: Double, roomId: UUID?, notes: String, imageData: Data?) {
        var entry = JobLogEntry(contactId: contactId, date: date, tasksDone: tasksDone, hoursWorked: hoursWorked, amountPaid: amountPaid, roomId: roomId, notes: notes)
        if let imgData = imageData {
            entry.imagePath = store.saveImage(imgData, for: entry.id)
        }
        store.addJobLogEntry(entry)
        if let uid = userId {
            let contactIds = Set(store.contacts(for: uid).map { $0.id })
            jobLogEntries = store.data.jobLogEntries.filter { contactIds.contains($0.contactId) }
        }
    }

    func deleteJobLogEntry(_ entry: JobLogEntry) {
        store.deleteJobLogEntry(entry)
        if let uid = userId {
            let contactIds = Set(store.contacts(for: uid).map { $0.id })
            jobLogEntries = store.data.jobLogEntries.filter { contactIds.contains($0.contactId) }
        }
    }

    // MARK: - Dashboard Stats

    var todayTasks: [RenovationTask] {
        tasks.filter { $0.isToday && $0.status != .completed }
    }

    var overdueTasks: [RenovationTask] {
        tasks.filter { $0.isOverdue }
    }

    var completedTasks: [RenovationTask] {
        tasks.filter { $0.status == .completed }
    }

    var taskProgress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(tasks.count)
    }

    var roomsCount: Int { rooms.count }

    // MARK: - Insights

    func mostExpensiveRoom() -> (Room, Double)? {
        guard !rooms.isEmpty else { return nil }
        let roomExpenses = rooms.map { room -> (Room, Double) in
            let roomMats = materials.filter { $0.roomId == room.id }
            let matCost = roomMats.reduce(0) { $0 + $1.totalCost }
            return (room, matCost)
        }
        return roomExpenses.max(by: { $0.1 < $1.1 })
    }

    func completedTasksPercentage() -> Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(tasks.count) * 100
    }

    func largestExpenseCategory() -> (ExpenseCategory, Double)? {
        spentByCategory().first
    }
}
