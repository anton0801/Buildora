import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()

                Group {
                    if dataVM.projects.isEmpty {
                        BEmptyState(
                            icon: "folder.badge.plus",
                            title: "No Projects Yet",
                            subtitle: "Start your first renovation project",
                            buttonTitle: "Create Project",
                            onButton: { showAdd = true }
                        )
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                ForEach(dataVM.projects) { project in
                                    ProjectCard(project: project)
                                        .environmentObject(dataVM)
                                        .environmentObject(appState)
                                }
                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        }
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
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddProjectView()
                .environmentObject(dataVM)
                .environmentObject(appState)
        }
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    let project: Project
    @State private var showActions = false

    private var projectTasks: [RenovationTask] { DataStore.shared.tasks(for: project.id) }
    private var completedCount: Int { projectTasks.filter { $0.status == .completed }.count }
    private var progress: Double {
        guard !projectTasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(projectTasks.count)
    }
    private var spent: Double { DataStore.shared.totalSpent(for: project.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.name)
                        .font(.bHeadline())
                        .foregroundColor(.bNavy)
                    HStack(spacing: 8) {
                        BTag(text: project.status.rawValue, color: Color(hex: project.status.color), small: true)
                        if appState.selectedProjectId == project.id {
                            BTag(text: "Active", color: .bGreen, small: true)
                        }
                    }
                }
                Spacer()
                Menu {
                    Button("Set as Active") {
                        appState.selectProject(project.id)
                        dataVM.reloadProject(project.id)
                    }
                    Button("Delete", role: .destructive) {
                        dataVM.deleteProject(project)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.bNavy.opacity(0.4))
                }
            }

            // Stats
            HStack(spacing: 0) {
                miniStat(value: "\(DataStore.shared.rooms(for: project.id).count)", label: "Rooms", color: .bBlue)
                miniStat(value: "\(projectTasks.count)", label: "Tasks", color: .bOrange)
                miniStat(value: appState.formatAmount(spent), label: "Spent", color: .bRed)
            }

            // Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progress")
                        .font(.bCaption())
                        .foregroundColor(.bNavy.opacity(0.5))
                    Spacer()
                    Text("\(completedCount)/\(projectTasks.count) tasks")
                        .font(.bCaption())
                        .foregroundColor(.bNavy.opacity(0.5))
                }
                BProgressBar(value: progress, color: .bGreen)
            }

            // Dates
            if let start = project.startDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.bNavy.opacity(0.4))
                    Text("Started \(start, style: .date)")
                        .font(.bCaption())
                        .foregroundColor(.bNavy.opacity(0.4))
                    if let end = project.endDate {
                        Text("· Due \(end, style: .date)")
                            .font(.bCaption())
                            .foregroundColor(.bRed.opacity(0.7))
                    }
                }
            }
        }
        .padding(16)
        .bCardStyle()
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.bCaption())
                .foregroundColor(.bNavy.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Project

struct AddProjectView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var description = ""
    @State private var budget = ""
    @State private var hasStartDate = false
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(86400 * 30)
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(LinearGradient.bYellowOrange)
                                .frame(width: 72, height: 72)
                            Image(systemName: "folder.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)

                        VStack(spacing: 12) {
                            BTextField(placeholder: "Project name *", text: $name, icon: "folder")
                            BTextField(placeholder: "Description (optional)", text: $description, icon: "text.alignleft")
                            BTextField(placeholder: "Total budget", text: $budget, icon: "dollarsign.circle", keyboardType: .decimalPad)
                        }

                        // Dates
                        VStack(spacing: 12) {
                            Toggle(isOn: $hasStartDate) {
                                Label("Set start date", systemImage: "calendar")
                                    .font(.bBody())
                                    .foregroundColor(.bNavy)
                            }
                            .tint(.bOrange)
                            if hasStartDate {
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .font(.bBody())
                            }

                            Toggle(isOn: $hasEndDate) {
                                Label("Set target date", systemImage: "flag")
                                    .font(.bBody())
                                    .foregroundColor(.bNavy)
                            }
                            .tint(.bOrange)
                            if hasEndDate {
                                DatePicker("Target Date", selection: $endDate, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .font(.bBody())
                            }
                        }
                        .padding(16)
                        .bCardStyle()

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.bCaption())
                                .foregroundColor(.bRed)
                        }

                        Button("Create Project") { save() }
                            .buttonStyle(BuildoraPrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a project name."
            return
        }
        dataVM.addProject(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description,
            budget: Double(budget) ?? 0,
            startDate: hasStartDate ? startDate : nil,
            endDate: hasEndDate ? endDate : nil
        )
        if let newProject = dataVM.projects.first {
            appState.selectProject(newProject.id)
        }
        presentationMode.wrappedValue.dismiss()
    }
}
