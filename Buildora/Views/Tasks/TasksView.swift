import SwiftUI

struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var filter: TaskFilter = .all
    @State private var searchText = ""

    enum TaskFilter: String, CaseIterable {
        case all       = "All"
        case today     = "Today"
        case overdue   = "Overdue"
        case inProgress = "In Progress"
        case completed = "Completed"
    }

    var filteredTasks: [RenovationTask] {
        var base = dataVM.tasks
        // Search
        if !searchText.isEmpty {
            base = base.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        // Filter
        switch filter {
        case .all:        return base
        case .today:      return base.filter { $0.isToday }
        case .overdue:    return base.filter { $0.isOverdue }
        case .inProgress: return base.filter { $0.status == .inProgress }
        case .completed:  return base.filter { $0.status == .completed }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.bNavy.opacity(0.4))
                        TextField("Search tasks…", text: $searchText)
                            .font(.bBody())
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(14)
                    .bShadow(0.05)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TaskFilter.allCases, id: \.self) { f in
                                filterChip(f)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)

                    // Summary bar
                    summaryBar

                    // Task list
                    if filteredTasks.isEmpty {
                        BEmptyState(
                            icon: "checkmark.circle",
                            title: filter == .completed ? "No completed tasks" : "No tasks found",
                            subtitle: filter == .all ? "Add your first task to get started" : "Try a different filter",
                            buttonTitle: filter == .all ? "Add Task" : nil,
                            onButton: filter == .all ? { showAdd = true } : nil
                        )
                    } else {
                        List {
                            ForEach(filteredTasks) { task in
                                TaskRow(task: task)
                                    .environmentObject(dataVM)
                                    .environmentObject(appState)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { i in dataVM.deleteTask(filteredTasks[i]) }
                            }
                            Spacer().frame(height: 80).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                        .listStyle(PlainListStyle())
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        BFAB(action: { showAdd = true }, color: .bOrange)
                            .padding(.trailing, 24)
                            .padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddTaskView().environmentObject(dataVM).environmentObject(appState)
        }
    }

    private func filterChip(_ f: TaskFilter) -> some View {
        let isSelected = filter == f
        let count: Int = {
            switch f {
            case .all:        return dataVM.tasks.count
            case .today:      return dataVM.todayTasks.count
            case .overdue:    return dataVM.overdueTasks.count
            case .inProgress: return dataVM.tasks.filter { $0.status == .inProgress }.count
            case .completed:  return dataVM.completedTasks.count
            }
        }()

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { filter = f }
        }) {
            HStack(spacing: 5) {
                Text(f.rawValue).font(.bCaption())
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .bOrange : .bNavy.opacity(0.5))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.bOrange.opacity(0.15) : Color.bGrayBeige.opacity(0.8))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : .bNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.bOrange : Color.white)
            .cornerRadius(20)
            .bShadow(isSelected ? 0.15 : 0.05)
        }
    }

    private var summaryBar: some View {
        HStack(spacing: 0) {
            StatBadge(value: "\(dataVM.tasks.count)", label: "Total", color: .bNavy)
            StatBadge(value: "\(dataVM.overdueTasks.count)", label: "Overdue", color: .bRed)
            StatBadge(value: "\(dataVM.completedTasks.count)", label: "Done", color: .bGreen)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Task Row

struct TaskRow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    let task: RenovationTask
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dataVM.toggleTaskComplete(task)
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(task.status == .completed ? Color.bGreen : Color.bGrayBeige, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if task.status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.bGreen)
                    }
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.bBody())
                    .foregroundColor(task.status == .completed ? .bNavy.opacity(0.4) : .bNavy)
                    .strikethrough(task.status == .completed, color: .bNavy.opacity(0.4))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    BTag(text: task.priority.rawValue, color: Color(hex: task.priority.color), small: true)
                    if task.isOverdue {
                        BTag(text: "Overdue", color: .bRed, small: true)
                    } else if task.isToday {
                        BTag(text: "Today", color: .bOrange, small: true)
                    } else if let due = task.dueDate {
                        Text(due, style: .date)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.bNavy.opacity(0.5))
                    }
                    if let roomId = task.roomId,
                       let room = dataVM.rooms.first(where: { $0.id == roomId }) {
                        Label(room.name, systemImage: "door.right.hand.open")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.bBlue.opacity(0.8))
                    }
                }
            }

            Spacer()

            Button(action: { showDetail = true }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.bNavy.opacity(0.3))
            }
        }
        .padding(14)
        .background(task.isOverdue ? Color.bRed.opacity(0.05) : Color.white)
        .cornerRadius(16)
        .bShadow(0.06)
        .sheet(isPresented: $showDetail) {
            TaskDetailView(task: task).environmentObject(dataVM).environmentObject(appState)
        }
    }
}

// MARK: - Task Detail

struct TaskDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let task: RenovationTask
    @State private var showEdit = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Status card
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(task.title).font(.bHeadline()).foregroundColor(.bNavy)
                                    HStack(spacing: 8) {
                                        BTag(text: task.priority.rawValue, color: Color(hex: task.priority.color))
                                        BTag(text: task.status.rawValue, color: Color(hex: task.status.color))
                                        if task.isOverdue { BTag(text: "Overdue", color: .bRed) }
                                    }
                                }
                                Spacer()
                            }
                            Button(action: {
                                dataVM.toggleTaskComplete(task)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Label(
                                    task.status == .completed ? "Mark as To Do" : "Mark as Complete",
                                    systemImage: task.status == .completed ? "circle" : "checkmark.circle.fill"
                                )
                            }
                            .buttonStyle(BuildoraPrimaryButtonStyle())
                        }
                        .padding(16).bCardStyle().padding(.horizontal, 20)

                        // Description
                        if !task.taskDescription.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description").font(.bSubhead()).foregroundColor(.bNavy)
                                Text(task.taskDescription).font(.bBody()).foregroundColor(.bNavy.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16).bCardStyle().padding(.horizontal, 20)
                        }

                        // Dates
                        VStack(spacing: 12) {
                            if let due = task.dueDate {
                                detailRow(icon: "calendar", label: "Due Date", value: due.formatted(.dateTime.day().month().year()))
                            }
                            if let roomId = task.roomId, let room = dataVM.rooms.first(where: { $0.id == roomId }) {
                                detailRow(icon: "door.right.hand.open", label: "Room", value: room.name)
                            }
                            detailRow(icon: "clock", label: "Created", value: task.createdAt.formatted(.dateTime.day().month().year()))
                            if let completed = task.completedAt {
                                detailRow(icon: "checkmark.circle", label: "Completed", value: completed.formatted(.dateTime.day().month().year()))
                            }
                        }
                        .padding(16).bCardStyle().padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Edit") { showEdit = true }
            )
        }
        .sheet(isPresented: $showEdit) {
            EditTaskView(task: task).environmentObject(dataVM).environmentObject(appState)
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.bOrange).frame(width: 24)
            Text(label).font(.bBody()).foregroundColor(.bNavy.opacity(0.6))
            Spacer()
            Text(value).font(.bBody()).foregroundColor(.bNavy)
        }
    }
}

// MARK: - Add Task

struct AddTaskView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var selectedRoomId: UUID? = nil
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Task title *", text: $title, icon: "checkmark.circle")
                        BTextField(placeholder: "Description (optional)", text: $description, icon: "text.alignleft")

                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: p.icon).font(.system(size: 12))
                                            Text(p.rawValue).font(.bCaption())
                                        }
                                        .foregroundColor(priority == p ? .white : Color(hex: p.color))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(priority == p ? Color(hex: p.color) : Color(hex: p.color).opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }

                        // Room
                        if !dataVM.rooms.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Assign to Room").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        Button("None") { selectedRoomId = nil }
                                            .font(.bCaption())
                                            .foregroundColor(selectedRoomId == nil ? .white : .bNavy)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(selectedRoomId == nil ? Color.bNavy : Color.bGrayBeige)
                                            .cornerRadius(20)
                                        ForEach(dataVM.rooms) { room in
                                            Button(room.name) { selectedRoomId = room.id }
                                                .font(.bCaption())
                                                .foregroundColor(selectedRoomId == room.id ? .white : .bNavy)
                                                .padding(.horizontal, 12).padding(.vertical, 8)
                                                .background(selectedRoomId == room.id ? Color.bBlue : Color.bGrayBeige)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }

                        // Due Date
                        VStack(spacing: 12) {
                            Toggle(isOn: $hasDueDate) {
                                Label("Set due date", systemImage: "calendar").font(.bBody()).foregroundColor(.bNavy)
                            }
                            .tint(.bOrange)
                            if hasDueDate {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                        }
                        .padding(16).bCardStyle()

                        if !errorMsg.isEmpty {
                            Text(errorMsg).font(.bCaption()).foregroundColor(.bRed)
                        }

                        Button("Add Task") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }

    private func save() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMsg = "Please enter a task title."; return
        }
        dataVM.addTask(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            roomId: selectedRoomId
        )
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Task

struct EditTaskView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let task: RenovationTask

    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var status: TaskStatus = .todo
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedRoomId: UUID? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Task title", text: $title, icon: "checkmark.circle")
                        BTextField(placeholder: "Description", text: $description, icon: "text.alignleft")

                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Picker("Status", selection: $status) {
                            ForEach(TaskStatus.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Toggle(isOn: $hasDueDate) {
                            Label("Due date", systemImage: "calendar").font(.bBody()).foregroundColor(.bNavy)
                        }
                        .tint(.bOrange)
                        if hasDueDate {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        }

                        Button("Save Changes") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear {
                title = task.title
                description = task.taskDescription
                priority = task.priority
                status = task.status
                hasDueDate = task.dueDate != nil
                dueDate = task.dueDate ?? Date()
                selectedRoomId = task.roomId
            }
        }
    }

    private func save() {
        var updated = task
        updated.title = title
        updated.taskDescription = description
        updated.priority = priority
        updated.status = status
        updated.dueDate = hasDueDate ? dueDate : nil
        updated.roomId = selectedRoomId
        if status == .completed && task.status != .completed { updated.completedAt = Date() }
        if status != .completed { updated.completedAt = nil }
        dataVM.updateTask(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
