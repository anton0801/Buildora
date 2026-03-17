import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Overview cards
                        overviewSection

                        // Most expensive room
                        mostExpensiveRoomSection

                        // Task completion
                        taskCompletionSection

                        // Largest expense category
                        expenseCategorySection

                        // Overdue alert
                        overdueSection

                        // Room progress overview
                        roomProgressSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                insightCard(
                    icon: "checkmark.circle.fill",
                    title: "Tasks Done",
                    value: "\(dataVM.completedTasks.count)/\(dataVM.tasks.count)",
                    subtitle: "\(Int(dataVM.completedTasksPercentage()))% complete",
                    gradient: .bGreenTeal
                )
                insightCard(
                    icon: "rectangle.3.group.fill",
                    title: "Rooms",
                    value: "\(dataVM.rooms.count)",
                    subtitle: "\(dataVM.rooms.filter { $0.stage == .done }.count) finished",
                    gradient: .bBlueTeal
                )
            }
            HStack(spacing: 12) {
                insightCard(
                    icon: "creditcard.fill",
                    title: "Total Spent",
                    value: appState.formatAmount(dataVM.totalSpent),
                    subtitle: "of \(appState.formatAmount(dataVM.totalBudget)) budget",
                    gradient: .bOrangeRed
                )
                insightCard(
                    icon: "cart.fill",
                    title: "Materials",
                    value: "\(dataVM.materials.count)",
                    subtitle: "\(dataVM.materials.filter { $0.inStock }.count) in stock",
                    gradient: .bYellowOrange
                )
            }
        }
    }

    private func insightCard(icon: String, title: String, value: String, subtitle: String, gradient: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.9))
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.bCaption())
                .foregroundColor(.white.opacity(0.9))
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(gradient)
        .cornerRadius(20)
        .bShadow(0.15)
    }

    // MARK: - Most Expensive Room

    private var mostExpensiveRoomSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Most Expensive Room") {}

            if let (room, cost) = dataVM.mostExpensiveRoom(), cost > 0 {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14).fill(Color.bRed.opacity(0.12)).frame(width: 52, height: 52)
                        Image(systemName: "dollarsign.circle.fill").font(.system(size: 26)).foregroundColor(.bRed)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(room.name).font(.bSubhead()).foregroundColor(.bNavy)
                        Text("Materials cost").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    }
                    Spacer()
                    Text(appState.formatAmount(cost)).font(.bHeadline()).foregroundColor(.bRed)
                }
                .padding(16).bCardStyle()
            } else {
                Text("Not enough data yet.").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).bCardStyle()
            }
        }
    }

    // MARK: - Task Completion

    private var taskCompletionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Task Completion") {}

            VStack(spacing: 12) {
                // Donut-style progress
                ZStack {
                    Circle()
                        .stroke(Color.bGrayBeige, lineWidth: 16)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: CGFloat(dataVM.taskProgress))
                        .stroke(LinearGradient.bGreenTeal, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: dataVM.taskProgress)
                    VStack(spacing: 2) {
                        Text("\(Int(dataVM.taskProgress * 100))%")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.bNavy)
                        Text("done").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 0) {
                    StatBadge(value: "\(dataVM.tasks.count)", label: "Total", color: .bNavy)
                    StatBadge(value: "\(dataVM.completedTasks.count)", label: "Completed", color: .bGreen)
                    StatBadge(value: "\(dataVM.overdueTasks.count)", label: "Overdue", color: .bRed)
                }
            }
            .padding(16).bCardStyle()
        }
    }

    // MARK: - Expense Category

    private var expenseCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Spending Breakdown") {}

            let breakdown = dataVM.spentByCategory()
            if breakdown.isEmpty {
                Text("No expenses recorded yet.").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).bCardStyle()
            } else {
                VStack(spacing: 10) {
                    ForEach(breakdown, id: \.0) { (cat, amount) in
                        HStack(spacing: 12) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 16)).foregroundColor(Color(hex: cat.color))
                                .frame(width: 32, height: 32)
                                .background(Color(hex: cat.color).opacity(0.12)).cornerRadius(8)
                            Text(cat.rawValue).font(.bBody()).foregroundColor(.bNavy)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(appState.formatAmount(amount)).font(.bBody()).foregroundColor(.bNavy)
                                if dataVM.totalSpent > 0 {
                                    Text("\(Int(amount / dataVM.totalSpent * 100))%")
                                        .font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                                }
                            }
                        }
                    }
                }
                .padding(16).bCardStyle()
            }
        }
    }

    // MARK: - Overdue Alert

    private var overdueSection: some View {
        Group {
            if !dataVM.overdueTasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.bRed)
                        Text("Overdue Tasks").font(.bSubhead()).foregroundColor(.bNavy)
                        BTag(text: "\(dataVM.overdueTasks.count)", color: .bRed)
                    }

                    VStack(spacing: 8) {
                        ForEach(dataVM.overdueTasks.prefix(3)) { task in
                            HStack(spacing: 10) {
                                Circle().fill(Color.bRed).frame(width: 8, height: 8)
                                Text(task.title).font(.bBody()).foregroundColor(.bNavy).lineLimit(1)
                                Spacer()
                                if let due = task.dueDate {
                                    Text(due, style: .relative).font(.bCaption()).foregroundColor(.bRed)
                                }
                            }
                            .padding(12).background(Color.bRed.opacity(0.06)).cornerRadius(12)
                        }
                    }
                }
                .padding(16).bCardStyle()
            }
        }
    }

    // MARK: - Room Progress

    private var roomProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Room Progress") {}

            if dataVM.rooms.isEmpty {
                Text("No rooms added yet.").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).bCardStyle()
            } else {
                VStack(spacing: 10) {
                    ForEach(dataVM.rooms) { room in
                        HStack(spacing: 12) {
                            Image(systemName: room.stage.icon)
                                .foregroundColor(Color(hex: room.stage.color))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(room.name).font(.bBody()).foregroundColor(.bNavy)
                                    Spacer()
                                    Text("\(Int(room.stage.progress * 100))%")
                                        .font(.bCaption()).foregroundColor(Color(hex: room.stage.color))
                                }
                                BProgressBar(value: room.stage.progress, color: Color(hex: room.stage.color), height: 6)
                            }
                        }
                    }
                }
                .padding(16).bCardStyle()
            }
        }
    }
}
