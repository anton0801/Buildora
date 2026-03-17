import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var tasksForSelectedDate: [RenovationTask] {
        dataVM.tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: selectedDate)
        }
    }

    var datesWithTasks: Set<DateComponents> {
        Set(dataVM.tasks.compactMap { $0.dueDate }.map {
            calendar.dateComponents([.year, .month, .day], from: $0)
        })
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Month navigator
                        monthNavigator

                        // Calendar grid
                        calendarGrid

                        // Tasks for selected date
                        selectedDateSection

                        // Upcoming deadlines
                        upcomingSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.bNavy)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .cornerRadius(12)
                    .bShadow(0.06)
            }

            Spacer()

            Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                .font(.bHeadline())
                .foregroundColor(.bNavy)

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.bNavy)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .cornerRadius(12)
                    .bShadow(0.06)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Day of week headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.bNavy.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(16)
        .bCardStyle()
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasTask = hasTasks(on: date)
        let overdue = hasOverdue(on: date)

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedDate = date }
        }) {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 15, weight: isToday || isSelected ? .bold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white : isToday ? .bOrange : .bNavy)

                if hasTask {
                    Circle()
                        .fill(overdue ? Color.bRed : Color.bGreen)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.bOrange : isToday ? Color.bOrange.opacity(0.1) : Color.clear)
            )
        }
    }

    // MARK: - Selected Date Section

    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: selectedDate.formatted(.dateTime.weekday(.wide).day().month())) {}

            if tasksForSelectedDate.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle").foregroundColor(.bGreen).font(.system(size: 24))
                    Text("No tasks on this day").font(.bBody()).foregroundColor(.bNavy.opacity(0.6))
                    Spacer()
                }
                .padding(16).bCardStyle()
            } else {
                VStack(spacing: 8) {
                    ForEach(tasksForSelectedDate) { task in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: task.priority.color))
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(task.title).font(.bBody()).foregroundColor(.bNavy).lineLimit(1)
                                HStack(spacing: 8) {
                                    BTag(text: task.priority.rawValue, color: Color(hex: task.priority.color), small: true)
                                    BTag(text: task.status.rawValue, color: Color(hex: task.status.color), small: true)
                                }
                            }
                            Spacer()
                        }
                        .padding(12).background(Color.white).cornerRadius(12).bShadow(0.05)
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        let upcoming = dataVM.tasks
            .filter { task in
                guard let due = task.dueDate else { return false }
                return due > Date() && task.status != .completed
            }
            .sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
            .prefix(5)

        return VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Upcoming Deadlines") {}

            if upcoming.isEmpty {
                Text("No upcoming deadlines.").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).bCardStyle()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(upcoming)) { task in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: task.priority.color).opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: task.priority.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: task.priority.color))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(task.title).font(.bBody()).foregroundColor(.bNavy).lineLimit(1)
                                if let due = task.dueDate {
                                    Text(due, style: .date).font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                                }
                            }
                            Spacer()
                            if let due = task.dueDate {
                                Text(due, style: .relative)
                                    .font(.bCaption()).foregroundColor(.bOrange)
                            }
                        }
                        .padding(12).background(Color.white).cornerRadius(14).bShadow(0.05)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func changeMonth(by value: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) ?? currentMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else { return [] }

        let weekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: weekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private func hasTasks(on date: Date) -> Bool {
        dataVM.tasks.contains { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: date)
        }
    }

    private func hasOverdue(on date: Date) -> Bool {
        dataVM.tasks.contains { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: date) && task.isOverdue
        }
    }
}
