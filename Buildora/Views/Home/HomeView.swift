import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showProjectPicker = false
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Active Project Card
                        activeProjectSection

                        // Today's Tasks
                        todayTasksSection

                        // Rooms Overview
                        roomsOverviewSection

                        // Budget Snapshot
                        budgetSnapshotSection

                        // Quick Actions
                        quickActionsSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }
        }
        .sheet(isPresented: $showProjectPicker) {
            ProjectPickerSheet()
                .environmentObject(dataVM)
                .environmentObject(appState)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(appState.currentUser?.name.components(separatedBy: " ").first ?? "Builder")! 👋")
                    .font(.bCaption())
                    .foregroundColor(.bNavy.opacity(0.6))
                Text("Your Renovation Hub")
                    .font(.bTitle())
                    .foregroundColor(.bNavy)
            }
            Spacer()
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient.bYellowOrange)
                    .frame(width: 48, height: 48)
                Text(String(appState.currentUser?.name.prefix(1) ?? "B"))
                    .font(.bHeadline())
                    .foregroundColor(.white)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)
    }

    // MARK: - Active Project

    private var activeProjectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Active Project", action: "Switch") {
                showProjectPicker = true
            }

            if let project = appState.selectedProject ?? dataVM.projects.first {
                NavigationLink(destination: ProjectDetailView(project: project).environmentObject(dataVM).environmentObject(appState)) {
                    activeProjectCard(project)
                }
                .buttonStyle(PlainButtonStyle())
                .onAppear {
                    if appState.selectedProjectId == nil, let p = dataVM.projects.first {
                        appState.selectProject(p.id)
                    }
                }
            } else {
                BEmptyState(icon: "folder.badge.plus", title: "No Projects", subtitle: "Create your first renovation project", buttonTitle: nil, onButton: nil)
                    .bCardStyle()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)
    }

    private func activeProjectCard(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.bHeadline())
                        .foregroundColor(.bNavy)
                    BTag(text: project.status.rawValue, color: Color(hex: project.status.color))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.bNavy.opacity(0.3))
            }

            let progress = dataVM.taskProgress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Overall Progress")
                        .font(.bCaption())
                        .foregroundColor(.bNavy.opacity(0.6))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.bCaption())
                        .foregroundColor(.bGreen)
                }
                BProgressBar(value: progress, color: .bGreen)
            }

            HStack(spacing: 0) {
                StatBadge(value: "\(dataVM.rooms.count)", label: "Rooms", color: .bBlue)
                StatBadge(value: "\(dataVM.tasks.count)", label: "Tasks", color: .bOrange)
                StatBadge(value: appState.formatAmount(dataVM.totalSpent), label: "Spent", color: .bRed)
            }
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color.white, Color.bSectionBG], startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(20)
        .bShadow()
    }

    // MARK: - Today's Tasks

    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Today's Tasks") {}

            if dataVM.todayTasks.isEmpty && dataVM.overdueTasks.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.bGreen)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All clear for today!")
                            .font(.bSubhead())
                            .foregroundColor(.bNavy)
                        Text("No tasks due today.")
                            .font(.bCaption())
                            .foregroundColor(.bNavy.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(16)
                .bCardStyle()
            } else {
                VStack(spacing: 8) {
                    ForEach(dataVM.overdueTasks.prefix(2)) { task in
                        HomeMiniTaskRow(task: task, color: .bRed, badge: "Overdue") {
                            dataVM.toggleTaskComplete(task)
                        }
                    }
                    ForEach(dataVM.todayTasks.prefix(3)) { task in
                        HomeMiniTaskRow(task: task, color: .bOrange, badge: "Today") {
                            dataVM.toggleTaskComplete(task)
                        }
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)
    }

    // MARK: - Rooms Overview

    private var roomsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Rooms") {}

            if dataVM.rooms.isEmpty {
                Text("No rooms added yet.")
                    .font(.bCaption())
                    .foregroundColor(.bNavy.opacity(0.5))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bCardStyle()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(dataVM.rooms.prefix(6)) { room in
                            HomeRoomCard(room: room)
                        }
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: appeared)
    }

    // MARK: - Budget Snapshot

    private var budgetSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Budget Snapshot") {}

            HStack(spacing: 12) {
                budgetCard(label: "Total", value: appState.formatAmount(dataVM.totalBudget), color: .bBlue, icon: "target")
                budgetCard(label: "Spent", value: appState.formatAmount(dataVM.totalSpent), color: .bRed, icon: "arrow.up.circle")
                budgetCard(label: "Left", value: appState.formatAmount(max(dataVM.remainingBudget, 0)), color: .bGreen, icon: "arrow.down.circle")
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: appeared)
    }

    private func budgetCard(label: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(.bNavy)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.bCaption())
                .foregroundColor(.bNavy.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .cornerRadius(16)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Quick Actions") {}

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionButton(icon: "checkmark.circle", label: "Add Task", color: .bOrange) {
                    // Handled via Tasks tab
                }
                QuickActionButton(icon: "shoppingcart", label: "Shopping", color: .bTeal) {}
                QuickActionButton(icon: "ruler", label: "Measure", color: .bBlue) {}
                QuickActionButton(icon: "camera", label: "Add Photo", color: .bGreen) {}
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35), value: appeared)
    }
}

// MARK: - Supporting Views

struct HomeMiniTaskRow: View {
    let task: RenovationTask
    let color: Color
    let badge: String
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.status == .completed ? .bGreen : color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.bBody())
                    .foregroundColor(.bNavy)
                    .strikethrough(task.status == .completed)
                    .lineLimit(1)
                BTag(text: badge, color: color, small: true)
            }
            Spacer()
            BTag(text: task.priority.rawValue, color: Color(hex: task.priority.color), small: true)
        }
        .padding(12)
        .background(color.opacity(0.06))
        .cornerRadius(14)
    }
}

struct HomeRoomCard: View {
    let room: Room

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: room.stage.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: room.stage.color))
                Spacer()
                BTag(text: room.stage.rawValue, color: Color(hex: room.stage.color), small: true)
            }
            Text(room.name)
                .font(.bSubhead())
                .foregroundColor(.bNavy)
                .lineLimit(1)
            if room.area > 0 {
                Text(String(format: "%.1f m²", room.area))
                    .font(.bCaption())
                    .foregroundColor(.bNavy.opacity(0.5))
            }
            BProgressBar(value: room.stage.progress, color: Color(hex: room.stage.color), height: 6)
        }
        .frame(width: 140)
        .padding(14)
        .bCardStyle()
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.12))
                    .cornerRadius(10)
                Text(label)
                    .font(.bBody())
                    .foregroundColor(.bNavy)
                Spacer()
            }
            .padding(12)
            .bCardStyle()
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Project Picker Sheet

struct ProjectPickerSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                List {
                    ForEach(dataVM.projects) { project in
                        Button(action: {
                            appState.selectProject(project.id)
                            dataVM.reloadProject(project.id)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(project.name).font(.bSubhead()).foregroundColor(.bNavy)
                                    BTag(text: project.status.rawValue, color: Color(hex: project.status.color), small: true)
                                }
                                Spacer()
                                if appState.selectedProjectId == project.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.bGreen)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Project")
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

// MARK: - Project Detail View (used from Home)

struct ProjectDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State var project: Project
    @State private var showEdit = false

    var body: some View {
        ZStack {
            Color.bBG.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Stats row
                    HStack(spacing: 0) {
                        StatBadge(value: "\(dataVM.rooms.count)", label: "Rooms", color: .bBlue)
                        StatBadge(value: "\(dataVM.tasks.count)", label: "Tasks", color: .bOrange)
                        StatBadge(value: "\(dataVM.completedTasks.count)", label: "Done", color: .bGreen)
                    }
                    .padding(16)
                    .bCardStyle()
                    .padding(.horizontal, 20)

                    // Progress
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Task Progress")
                                .font(.bSubhead()).foregroundColor(.bNavy)
                            Spacer()
                            Text("\(Int(dataVM.taskProgress * 100))%")
                                .font(.bSubhead()).foregroundColor(.bGreen)
                        }
                        BProgressBar(value: dataVM.taskProgress, color: .bGreen)
                    }
                    .padding(16).bCardStyle().padding(.horizontal, 20)

                    // Description
                    if !project.projectDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description").font(.bSubhead()).foregroundColor(.bNavy)
                            Text(project.projectDescription).font(.bBody()).foregroundColor(.bNavy.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16).bCardStyle().padding(.horizontal, 20)
                    }

                    // Budget
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Budget").font(.bSubhead()).foregroundColor(.bNavy)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Budget").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                Text(appState.formatAmount(project.totalBudget)).font(.bHeadline()).foregroundColor(.bNavy)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Spent").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                Text(appState.formatAmount(dataVM.totalSpent)).font(.bHeadline()).foregroundColor(.bRed)
                            }
                        }
                        BProgressBar(value: dataVM.budgetProgress, color: dataVM.budgetProgress > 0.9 ? .bRed : .bBlue)
                    }
                    .padding(16).bCardStyle().padding(.horizontal, 20)

                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(project.name)
        .navigationBarItems(trailing: Button("Edit") { showEdit = true })
        .sheet(isPresented: $showEdit) {
            EditProjectView(project: $project)
                .environmentObject(dataVM)
        }
    }
}

struct EditProjectView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var project: Project

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var budget: String = ""
    @State private var status: ProjectStatus = .planning

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Project name", text: $name, icon: "folder")
                        BTextField(placeholder: "Description", text: $description, icon: "text.alignleft")
                        BTextField(placeholder: "Total budget", text: $budget, icon: "dollarsign.circle", keyboardType: .decimalPad)
                        Picker("Status", selection: $status) {
                            ForEach(ProjectStatus.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    project.name = name
                    project.projectDescription = description
                    project.totalBudget = Double(budget) ?? project.totalBudget
                    project.status = status
                    dataVM.updateProject(project)
                    presentationMode.wrappedValue.dismiss()
                }.foregroundColor(.bOrange)
            )
            .onAppear {
                name = project.name
                description = project.projectDescription
                budget = "\(Int(project.totalBudget))"
                status = project.status
            }
        }
    }
}
