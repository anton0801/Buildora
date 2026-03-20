import SwiftUI

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Gantt View

struct GanttView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @EnvironmentObject var appState: AppState

    @State private var dayWidth: CGFloat = 14
    @State private var selectedRoom: Room? = nil
    @State private var showRoomDetail = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil
    @State private var scrollTarget: String? = nil
    @State private var isBarGrabbed = false

    private let rowHeight: CGFloat = 52
    private let leftWidth: CGFloat = 100
    private let dateHeaderHeight: CGFloat = 44
    private let cal = Calendar.current

    private var roomsWithDates: [Room] {
        dataVM.rooms.filter { $0.startDate != nil && $0.endDate != nil }
            .sorted { ($0.startDate ?? Date()) < ($1.startDate ?? Date()) }
    }

    private var chartRange: (start: Date, end: Date) {
        guard !roomsWithDates.isEmpty else {
            let today = Date()
            return (cal.date(byAdding: .day, value: -3, to: today) ?? today,
                    cal.date(byAdding: .day, value: 30, to: today) ?? today)
        }
        let starts = roomsWithDates.compactMap { $0.startDate }
        let ends = roomsWithDates.compactMap { $0.endDate }
        let minDate = starts.min() ?? Date()
        let maxDate = ends.max() ?? Date()
        return (cal.date(byAdding: .day, value: -2, to: minDate) ?? minDate,
                cal.date(byAdding: .day, value: 4, to: maxDate) ?? maxDate)
    }

    private var totalDays: Int {
        max(cal.dateComponents([.day], from: chartRange.start, to: chartRange.end).day ?? 30, 1)
    }

    private var totalChartWidth: CGFloat {
        CGFloat(totalDays) * dayWidth + leftWidth
    }

    private var todayXOffset: CGFloat {
        let days = cal.dateComponents([.day], from: chartRange.start, to: Date()).day ?? 0
        return CGFloat(days) * dayWidth + leftWidth
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()

                if roomsWithDates.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        toolbar
                        Divider()
                        ganttChart
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showRoomDetail) {
                if let room = selectedRoom {
                    RoomDetailView(room: room)
                        .environmentObject(dataVM)
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let img = shareImage {
                    ShareSheet(activityItems: [img])
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button(action: { scrollTarget = "today" }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                    Text("Today")
                }
                .font(.bCaption())
                .foregroundColor(.bNavy)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.bSectionBG)
                .cornerRadius(20)
            }

            Button(action: fitAll) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.and.right")
                    Text("Fit All")
                }
                .font(.bCaption())
                .foregroundColor(.bNavy)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.bSectionBG)
                .cornerRadius(20)
            }

            Spacer()

            Button(action: shareChart) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.bCaption())
                .foregroundColor(.bOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.bOrange.opacity(0.12))
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.bBG)
    }

    // MARK: - Gantt Chart

    private var ganttChart: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .topLeading) {
                // Scrollable chart
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Chart body
                        VStack(spacing: 0) {
                            dateHeader
                                .padding(.leading, leftWidth)

                            ForEach(roomsWithDates) { room in
                                GanttRoomRow(
                                    room: room,
                                    tasks: dataVM.tasks.filter { $0.roomId == room.id },
                                    chartStart: chartRange.start,
                                    dayWidth: dayWidth,
                                    rowHeight: rowHeight,
                                    leftWidth: leftWidth,
                                    onTap: {
                                        selectedRoom = room
                                        showRoomDetail = true
                                    },
                                    onUpdate: { dataVM.updateRoom($0) }
                                )
                            }
                        }

                        // Today line
                        let todayX = todayXOffset
                        if todayX > leftWidth && todayX < totalChartWidth {
                            Rectangle()
                                .fill(Color.red.opacity(0.7))
                                .frame(width: 2, height: dateHeaderHeight + CGFloat(roomsWithDates.count) * rowHeight)
                                .offset(x: todayX)

                            // "Today" label
                            Text("Today")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                                .offset(x: todayX - 16, y: 2)
                                .id("today")
                        }
                    }
                    .frame(width: totalChartWidth)
                    .gesture(magnifyGesture)
                }
                .scrollDisabled(isBarGrabbed)

                // Fixed left column overlay (room names)
                leftColumn
                    .background(Color.bBG.opacity(0.97))
            }
            .onChange(of: scrollTarget) { target in
                guard let t = target else { return }
                withAnimation(.easeInOut(duration: 0.4)) { proxy.scrollTo(t, anchor: .center) }
                scrollTarget = nil
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    scrollTarget = "today"
                }
            }
        }
    }

    // MARK: - Left Column (fixed overlay)

    private var leftColumn: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: dateHeaderHeight)
            ForEach(roomsWithDates) { room in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: room.stage.color))
                        .frame(width: 8, height: 8)
                    Text(room.name)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.bNavy)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Spacer()
                }
                .frame(height: rowHeight)
                .padding(.horizontal, 10)
                .background(Color.clear)
            }
        }
        .frame(width: leftWidth)
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        GeometryReader { _ in
            Canvas { ctx, size in
                let totalD = totalDays
                for i in 0..<totalD {
                    guard let date = cal.date(byAdding: .day, value: i, to: chartRange.start) else { continue }
                    let x = CGFloat(i) * dayWidth
                    let dayNum = cal.component(.day, from: date)

                    // Month label at start of month
                    if dayNum == 1 || i == 0 {
                        let monthText = date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
                        let resolved = ctx.resolve(
                            Text(monthText)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.bNavy)
                        )
                        ctx.draw(resolved, at: CGPoint(x: x + 2, y: 4), anchor: .topLeading)
                    }

                    // Day number (skip if too narrow)
                    if dayWidth >= 12 || i % 3 == 0 {
                        let isToday = cal.isDateInToday(date)
                        let resolved = ctx.resolve(
                            Text("\(dayNum)")
                                .font(.system(size: 10, weight: isToday ? .bold : .regular, design: .rounded))
                                .foregroundColor(isToday ? Color.red : Color.bNavy.opacity(0.5))
                        )
                        ctx.draw(resolved, at: CGPoint(x: x + dayWidth / 2, y: 28), anchor: .center)
                    }

                    // Month start grid line
                    if dayNum == 1 {
                        ctx.stroke(Path { p in
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x, y: size.height))
                        }, with: .color(Color.bGrayBeige.opacity(0.5)), lineWidth: 0.5)
                    }
                }
            }
        }
        .frame(height: dateHeaderHeight)
    }

    // MARK: - Magnify Gesture

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newWidth = dayWidth * value
                dayWidth = min(max(newWidth, 8), 28)
            }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.bGrayBeige)
            Text("No Timeline Data")
                .font(.bHeadline())
                .foregroundColor(.bNavy)
            Text("Add start and end dates to your rooms to see the timeline")
                .font(.bBody())
                .foregroundColor(.bNavy.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func fitAll() {
        guard !roomsWithDates.isEmpty else { return }
        let screenWidth = UIScreen.main.bounds.width - leftWidth - 32
        let newWidth = screenWidth / CGFloat(max(totalDays, 1))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dayWidth = min(max(newWidth, 8), 28)
        }
    }

    @MainActor
    private func shareChart() {
        let exportView = GanttExportView(
            rooms: roomsWithDates,
            tasks: dataVM.tasks,
            chartStart: chartRange.start,
            chartEnd: chartRange.end,
            dayWidth: dayWidth
        )
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale
        if let img = renderer.uiImage {
            shareImage = img
            showShareSheet = true
        }
    }
}

// MARK: - Gantt Room Row

struct GanttRoomRow: View {
    let room: Room
    let tasks: [RenovationTask]
    let chartStart: Date
    let dayWidth: CGFloat
    let rowHeight: CGFloat
    let leftWidth: CGFloat
    let onTap: () -> Void
    let onUpdate: (Room) -> Void

    @State private var barOffset: CGFloat = 0
    @State private var leftOffset: CGFloat = 0
    @State private var rightOffset: CGFloat = 0
    @State private var isDragging = false

    private let cal = Calendar.current

    private var progress: Double {
        let total = tasks.count
        guard total > 0 else { return 0 }
        return Double(tasks.filter { $0.status == .completed }.count) / Double(total)
    }

    private var baseBarX: CGFloat {
        guard let startDate = room.startDate else { return leftWidth }
        let days = cal.dateComponents([.day], from: chartStart, to: startDate).day ?? 0
        return CGFloat(days) * dayWidth + leftWidth
    }

    private var baseBarWidth: CGFloat {
        guard let s = room.startDate, let e = room.endDate else { return dayWidth * 7 }
        let days = max(cal.dateComponents([.day], from: s, to: e).day ?? 1, 1)
        return CGFloat(days) * dayWidth
    }

    private var displayBarX: CGFloat { baseBarX + barOffset + leftOffset }
    private var displayBarWidth: CGFloat { baseBarWidth + rightOffset - leftOffset }
    private var barColor: Color { Color(hex: room.stage.color) }

    var body: some View {
        ZStack(alignment: .leading) {
            // Row background
            Color.bSectionBG.opacity(0.4)
                .frame(height: rowHeight)

            // Horizontal grid line
            Rectangle()
                .fill(Color.bGrayBeige.opacity(0.5))
                .frame(height: 0.5)
                .offset(y: rowHeight / 2)

            // Bar
            ZStack(alignment: .leading) {
                // Ghost (total duration)
                RoundedRectangle(cornerRadius: 8)
                    .fill(barColor.opacity(0.18))
                    .frame(width: max(displayBarWidth, dayWidth), height: rowHeight - 16)

                // Progress fill
                RoundedRectangle(cornerRadius: 8)
                    .fill(barColor.opacity(0.85))
                    .frame(width: max(displayBarWidth * CGFloat(progress), 0), height: rowHeight - 16)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Border
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(barColor, lineWidth: 1)
                    .frame(width: max(displayBarWidth, dayWidth), height: rowHeight - 16)

                // Left resize handle
                Capsule()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 3, height: rowHeight - 24)
                    .offset(x: 8)
                    .gesture(leftHandleDrag)

                // Right resize handle
                Capsule()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 3, height: rowHeight - 24)
                    .offset(x: max(displayBarWidth, dayWidth) - 11)
                    .gesture(rightHandleDrag)
            }
            .offset(x: displayBarX, y: 0)
            .gesture(barMoveDrag)
            .onTapGesture(perform: onTap)
        }
        .frame(height: rowHeight)
        .clipped()
    }

    // MARK: - Drag Gestures

    private var barMoveDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                isDragging = true
                barOffset = value.translation.width
            }
            .onEnded { value in
                guard isDragging else { return }
                let daysDelta = Int(round(value.translation.width / dayWidth))
                applyDelta(daysDelta, mode: .move)
                barOffset = 0
                isDragging = false
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
    }

    private var leftHandleDrag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in leftOffset = value.translation.width }
            .onEnded { value in
                let daysDelta = Int(round(value.translation.width / dayWidth))
                applyDelta(daysDelta, mode: .resizeStart)
                leftOffset = 0
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
    }

    private var rightHandleDrag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in rightOffset = value.translation.width }
            .onEnded { value in
                let daysDelta = Int(round(value.translation.width / dayWidth))
                applyDelta(daysDelta, mode: .resizeEnd)
                rightOffset = 0
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
    }

    private enum DragMode { case move, resizeStart, resizeEnd }

    private func applyDelta(_ days: Int, mode: DragMode) {
        var updated = room
        switch mode {
        case .move:
            updated.startDate = updated.startDate.map { cal.date(byAdding: .day, value: days, to: $0) ?? $0 }
            updated.endDate = updated.endDate.map { cal.date(byAdding: .day, value: days, to: $0) ?? $0 }
        case .resizeStart:
            updated.startDate = updated.startDate.map { cal.date(byAdding: .day, value: days, to: $0) ?? $0 }
        case .resizeEnd:
            updated.endDate = updated.endDate.map { cal.date(byAdding: .day, value: days, to: $0) ?? $0 }
        }
        // Ensure start <= end
        if let s = updated.startDate, let e = updated.endDate, s >= e {
            updated.endDate = cal.date(byAdding: .day, value: 1, to: s)
        }
        onUpdate(updated)
    }
}

// MARK: - Gantt Export View (for PNG rendering)

struct GanttExportView: View {
    let rooms: [Room]
    let tasks: [RenovationTask]
    let chartStart: Date
    let chartEnd: Date
    let dayWidth: CGFloat

    private let rowHeight: CGFloat = 44
    private let leftWidth: CGFloat = 100
    private let dateHeaderHeight: CGFloat = 36
    private let cal = Calendar.current

    private var totalDays: Int {
        max(cal.dateComponents([.day], from: chartStart, to: chartEnd).day ?? 30, 1)
    }

    private var todayOffset: CGFloat {
        let days = cal.dateComponents([.day], from: chartStart, to: Date()).day ?? 0
        return CGFloat(days) * dayWidth + leftWidth
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Renovation Timeline")
                    .font(.bHeadline())
                    .foregroundColor(.bNavy)
                Spacer()
                Text(Date().formatted(.dateTime.day().month().year()))
                    .font(.bCaption())
                    .foregroundColor(.bNavy.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "FFF8EC"))

            HStack(spacing: 0) {
                // Left labels
                VStack(spacing: 0) {
                    Color.clear.frame(height: dateHeaderHeight)
                    ForEach(rooms) { room in
                        Text(room.name)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.bNavy)
                            .lineLimit(1)
                            .frame(width: leftWidth, height: rowHeight, alignment: .leading)
                            .padding(.leading, 8)
                    }
                }

                // Chart area
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        // Date header
                        HStack(spacing: 0) {
                            ForEach(0..<totalDays, id: \.self) { i in
                                if let date = cal.date(byAdding: .day, value: i, to: chartStart) {
                                    let dayNum = cal.component(.day, from: date)
                                    if dayNum == 1 || i == 0 {
                                        Text(date.formatted(.dateTime.month(.abbreviated)))
                                            .font(.system(size: 8, weight: .bold, design: .rounded))
                                            .foregroundColor(.bNavy)
                                            .frame(width: dayWidth, height: dateHeaderHeight, alignment: .leading)
                                    } else {
                                        Color.clear.frame(width: dayWidth, height: dateHeaderHeight)
                                    }
                                }
                            }
                        }

                        // Room bars
                        ForEach(rooms) { room in
                            exportBar(room: room)
                                .frame(height: rowHeight)
                        }
                    }

                    // Today line
                    Rectangle()
                        .fill(Color.red.opacity(0.6))
                        .frame(width: 1.5, height: dateHeaderHeight + CGFloat(rooms.count) * rowHeight)
                        .offset(x: todayOffset)
                }
                .frame(width: CGFloat(totalDays) * dayWidth)
            }
        }
        .background(Color(hex: "FFF8EC"))
        .frame(width: leftWidth + CGFloat(totalDays) * dayWidth)
    }

    private func exportBar(room: Room) -> some View {
        let barX: CGFloat = {
            guard let s = room.startDate else { return leftWidth }
            let d = cal.dateComponents([.day], from: chartStart, to: s).day ?? 0
            return CGFloat(d) * dayWidth
        }()
        let barW: CGFloat = {
            guard let s = room.startDate, let e = room.endDate else { return dayWidth * 7 }
            let d = max(cal.dateComponents([.day], from: s, to: e).day ?? 1, 1)
            return CGFloat(d) * dayWidth
        }()
        let roomTasks = tasks.filter { $0.roomId == room.id }
        let prog: Double = roomTasks.isEmpty ? 0 : Double(roomTasks.filter { $0.status == .completed }.count) / Double(roomTasks.count)
        let color = Color(hex: room.stage.color)

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.18)).frame(width: barW, height: rowHeight - 12)
            RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.85)).frame(width: barW * CGFloat(prog), height: rowHeight - 12).clipShape(RoundedRectangle(cornerRadius: 6))
            RoundedRectangle(cornerRadius: 6).strokeBorder(color, lineWidth: 1).frame(width: barW, height: rowHeight - 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, barX)
    }
}
