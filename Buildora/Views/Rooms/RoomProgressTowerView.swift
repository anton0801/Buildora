import SwiftUI

// MARK: - Room Tower Card

struct RoomTowerCard: View {
    let room: Room
    let tasks: [RenovationTask]

    private var completed: Int { tasks.filter { $0.status == .completed }.count }
    private var total: Int { tasks.count }
    private var progress: Double { total > 0 ? Double(completed) / Double(total) : 0 }
    private var stageColor: Color { Color(hex: room.stage.color) }

    private let maxBlocks = 8
    private let blockH: CGFloat = 14
    private let blockW: CGFloat = 52
    private let blockGap: CGFloat = 2

    private var displayTotal: Int { min(max(total, 1), maxBlocks) }
    private var displayDone: Int {
        guard total > 0 else { return 0 }
        return min(Int(round(Double(completed) / Double(total) * Double(displayTotal))), displayTotal)
    }
    private var displayGhost: Int { displayTotal - displayDone }

    @State private var animDone: Int = 0

    private var towerHeight: CGFloat {
        CGFloat(maxBlocks) * (blockH + blockGap) + 4
    }

    var body: some View {
        VStack(spacing: 8) {
            towerStack
                .frame(width: blockW, height: towerHeight)

            Text(room.name)
                .font(.bCaption())
                .foregroundColor(.bNavy)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 76)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(total == 0 ? .bGrayBeige : stageColor)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(Color.white)
        .cornerRadius(18)
        .bShadow(0.08)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.interpolatingSpring(stiffness: 160, damping: 14)) {
                    animDone = displayDone
                }
            }
        }
        .onChange(of: completed) { _ in
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 15)) {
                animDone = displayDone
            }
        }
    }

    @ViewBuilder
    private var towerStack: some View {
        if total == 0 {
            VStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.bGrayBeige)
                        .frame(width: blockW, height: blockH + 6)
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.bNavy.opacity(0.4))
                }
            }
        } else {
            VStack(spacing: blockGap) {
                Spacer(minLength: 0)
                ForEach(0..<displayGhost, id: \.self) { _ in
                    ghostBlock
                }
                ForEach(0..<animDone, id: \.self) { _ in
                    solidBlock
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
    }

    private var ghostBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(stageColor.opacity(0.07))
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(stageColor.opacity(0.25), lineWidth: 1.5)
        }
        .frame(width: blockW, height: blockH)
    }

    private var solidBlock: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(stageColor)
            .frame(width: blockW, height: blockH)
            .shadow(color: stageColor.opacity(0.3), radius: 2, y: 1)
    }
}

// MARK: - Room Tower Row

struct RoomTowerRow: View {
    @EnvironmentObject var dataVM: DataViewModel
    @EnvironmentObject var appState: AppState
    let rooms: [Room]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(rooms) { room in
                    NavigationLink(
                        destination: RoomDetailView(room: room)
                            .environmentObject(dataVM)
                            .environmentObject(appState)
                    ) {
                        RoomTowerCard(
                            room: room,
                            tasks: dataVM.tasks.filter { $0.roomId == room.id }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }
}
