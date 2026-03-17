import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var dataVM = DataViewModel()
    @State private var selectedTab = 0
    @State private var showMore = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .environmentObject(dataVM)
                    .tag(0)

                ProjectsView()
                    .environmentObject(dataVM)
                    .tag(1)

                TasksView()
                    .environmentObject(dataVM)
                    .tag(2)

                BudgetView()
                    .environmentObject(dataVM)
                    .tag(3)

                // Placeholder for "More" tab — actual content via sheet
                Color.clear.tag(4)
            }
            .accentColor(.bOrange)

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            if let user = appState.currentUser {
                dataVM.load(userId: user.id, projectId: appState.selectedProjectId)
            }
            // Hide default tab bar
            UITabBar.appearance().isHidden = true
        }
        .onChange(of: appState.selectedProjectId) { pid in
            if let pid = pid { dataVM.reloadProject(pid) }
        }
        .sheet(isPresented: $showMore) {
            MoreView()
                .environmentObject(dataVM)
                .environmentObject(appState)
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house.fill",    label: "Home",     tag: 0)
            tabItem(icon: "folder.fill",   label: "Projects", tag: 1)
            tabItem(icon: "checkmark.circle.fill", label: "Tasks", tag: 2)
            tabItem(icon: "chart.bar.fill", label: "Budget",  tag: 3)

            // More button
            Button(action: { showMore = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.bNavy.opacity(0.4))
                    Text("More")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.bNavy.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(
            Color(.systemBackground)
                .shadow(color: Color.bNavy.opacity(0.08), radius: 16, x: 0, y: -4)
        )
        .overlay(
            Rectangle()
                .fill(Color.bGrayBeige.opacity(0.5))
                .frame(height: 1),
            alignment: .top
        )
    }

    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == tag ? .bOrange : .bNavy.opacity(0.4))
                    .scaleEffect(selectedTab == tag ? 1.15 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(selectedTab == tag ? .bOrange : .bNavy.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}
