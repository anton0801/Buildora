import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var showExportConfirm = false
    @State private var exportedJSON = ""
    @State private var showExportSheet = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile card
                        profileCard

                        // Appearance
                        settingsSection("Appearance", icon: "paintbrush.fill", color: .bOrange) {
                            themeRow
                        }

                        // Regional
                        settingsSection("Regional", icon: "globe", color: .bBlue) {
                            currencyRow
                            Divider().padding(.horizontal, 4)
                            unitsRow
                        }

                        // Notifications
                        settingsSection("Notifications", icon: "bell.fill", color: .bYellow) {
                            notificationsRow
                            if appState.notificationsEnabled {
                                Divider().padding(.horizontal, 4)
                                deadlineNotifRow
                                Divider().padding(.horizontal, 4)
                                budgetNotifRow
                            }
                        }

                        // Data
                        settingsSection("Data", icon: "externaldrive.fill", color: .bTeal) {
                            exportRow
                        }

                        // Account
                        settingsSection("Account", icon: "person.crop.circle", color: .bRed) {
                            logoutRow
                            Divider().padding(.horizontal, 4)
                            deleteAccountRow
                        }

                        // App info
                        VStack(spacing: 4) {
                            Text("Buildora v1.0")
                                .font(.bCaption()).foregroundColor(.bNavy.opacity(0.4))
                            Text("Plan repairs step by step")
                                .font(.system(size: 11, design: .rounded)).foregroundColor(.bNavy.opacity(0.3))
                        }
                        .padding(.top, 8).padding(.bottom, 80)
                    }
                    .padding(.horizontal, 20).padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
        .onAppear { checkNotificationStatus() }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { appState.deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all renovation data. This cannot be undone.")
        }
        .alert("Sign Out", isPresented: $showLogoutConfirm) {
            Button("Sign Out", role: .destructive) { appState.logout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(activityItems: [exportedJSON])
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient.bYellowOrange)
                    .frame(width: 64, height: 64)
                Text(String(appState.currentUser?.name.prefix(2) ?? "BU"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.currentUser?.name ?? "User")
                    .font(.bHeadline()).foregroundColor(.bNavy)
                Text(appState.currentUser?.email ?? "")
                    .font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                Text("Member since \(appState.currentUser?.createdAt.formatted(.dateTime.month().year()) ?? "")")
                    .font(.bCaption()).foregroundColor(.bNavy.opacity(0.4))
            }
            Spacer()
        }
        .padding(16).bCardStyle()
    }

    // MARK: - Section Builder

    private func settingsSection<Content: View>(_ title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                Text(title).font(.bSubhead()).foregroundColor(.bNavy)
            }
            VStack(spacing: 0) {
                content()
            }
            .padding(16).bCardStyle()
        }
    }

    // MARK: - Theme Row

    private var themeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("App Theme").font(.bBody()).foregroundColor(.bNavy)
            HStack(spacing: 8) {
                ForEach([("Light", "sun.max.fill", "light"), ("Dark", "moon.fill", "dark"), ("System", "circle.lefthalf.filled", "system")], id: \.2) { label, icon, value in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            appState.theme = value
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: icon).font(.system(size: 18))
                            Text(label).font(.bCaption())
                        }
                        .foregroundColor(appState.theme == value ? .white : .bNavy)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(appState.theme == value ? Color.bOrange : Color.bGrayBeige)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Currency Row

    private var currencyRow: some View {
        HStack {
            Label("Currency", systemImage: "dollarsign.circle").font(.bBody()).foregroundColor(.bNavy)
            Spacer()
            Picker("", selection: $appState.currency) {
                Text("USD $").tag("USD")
                Text("EUR €").tag("EUR")
                Text("GBP £").tag("GBP")
                Text("RUB ₽").tag("RUB")
                Text("UAH ₴").tag("UAH")
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(.bOrange)
        }
    }

    // MARK: - Units Row

    private var unitsRow: some View {
        HStack {
            Label("Measurement Unit", systemImage: "ruler").font(.bBody()).foregroundColor(.bNavy)
            Spacer()
            Picker("", selection: $appState.measurementUnit) {
                Text("Meters (m)").tag("m")
                Text("Feet (ft)").tag("ft")
                Text("Centimeters (cm)").tag("cm")
                Text("Inches (in)").tag("in")
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(.bOrange)
        }
    }

    // MARK: - Notification Rows

    private var notificationsRow: some View {
        HStack {
            Label("Enable Notifications", systemImage: "bell").font(.bBody()).foregroundColor(.bNavy)
            Spacer()
            Toggle("", isOn: Binding(
                get: { appState.notificationsEnabled },
                set: { newVal in
                    appState.toggleNotifications(newVal)
                    checkNotificationStatus()
                }
            ))
            .tint(.bOrange)
        }
    }

    private var deadlineNotifRow: some View {
        HStack {
            Label("Deadline Reminders", systemImage: "calendar.badge.clock").font(.bBody()).foregroundColor(.bNavy)
            Spacer()
            Toggle("", isOn: $appState.deadlineNotifications)
                .tint(.bOrange)
                .onChange(of: appState.deadlineNotifications) { enabled in
                    if !enabled { NotificationManager.shared.cancelNotifications(withPrefix: "task_") }
                }
        }
    }

    private var budgetNotifRow: some View {
        HStack {
            Label("Budget Alerts", systemImage: "chart.bar.fill").font(.bBody()).foregroundColor(.bNavy)
            Spacer()
            Toggle("", isOn: $appState.budgetNotifications).tint(.bOrange)
        }
    }

    // MARK: - Export Row

    private var exportRow: some View {
        Button(action: exportData) {
            HStack {
                Label("Export Data", systemImage: "square.and.arrow.up").font(.bBody()).foregroundColor(.bNavy)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.bNavy.opacity(0.3))
            }
        }
    }

    // MARK: - Account Rows

    private var logoutRow: some View {
        Button(action: { showLogoutConfirm = true }) {
            HStack {
                Label("Sign Out", systemImage: "arrow.right.square").font(.bBody()).foregroundColor(.bOrange)
                Spacer()
            }
        }
    }

    private var deleteAccountRow: some View {
        Button(action: { showDeleteConfirm = true }) {
            HStack {
                Label("Delete Account & Data", systemImage: "trash").font(.bBody()).foregroundColor(.bRed)
                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private func checkNotificationStatus() {
        NotificationManager.shared.checkPermission { status in
            notificationStatus = status
            if status == .denied { appState.notificationsEnabled = false }
        }
    }

    private func exportData() {
        guard let userId = appState.currentUser?.id else { return }
        let store = DataStore.shared
        let exportData = ExportData(
            projects: store.projects(for: userId),
            rooms: store.data.rooms.filter { r in store.projects(for: userId).contains(where: { $0.id == r.projectId }) },
            tasks: store.allTasks(for: userId),
            expenses: store.data.expenses.filter { e in store.projects(for: userId).contains(where: { $0.id == e.projectId }) },
            contacts: store.contacts(for: userId)
        )
        if let json = try? JSONEncoder().encode(exportData),
           let str = String(data: json, encoding: .utf8) {
            exportedJSON = str
            showExportSheet = true
        }
    }
}

// MARK: - Export Data Model

private struct ExportData: Codable {
    let projects: [Project]
    let rooms: [Room]
    let tasks: [RenovationTask]
    let expenses: [BudgetExpense]
    let contacts: [Contact]
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
