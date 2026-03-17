import SwiftUI

struct RoomsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()

                Group {
                    if dataVM.rooms.isEmpty {
                        BEmptyState(
                            icon: "rectangle.3.group",
                            title: "No Rooms Yet",
                            subtitle: "Add rooms to organize your renovation",
                            buttonTitle: "Add Room",
                            onButton: { showAdd = true }
                        )
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(dataVM.rooms) { room in
                                    NavigationLink(destination: RoomDetailView(room: room).environmentObject(dataVM).environmentObject(appState)) {
                                        RoomCard(room: room)
                                            .environmentObject(dataVM)
                                            .environmentObject(appState)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        }
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        BFAB(action: { showAdd = true }, color: .bBlue)
                            .padding(.trailing, 24)
                            .padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Rooms")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddRoomView().environmentObject(dataVM).environmentObject(appState)
        }
    }
}

// MARK: - Room Card

struct RoomCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    let room: Room

    private var roomTasks: [RenovationTask] { dataVM.tasks.filter { $0.roomId == room.id } }
    private var completedTasks: Int { roomTasks.filter { $0.status == .completed }.count }
    private var roomMaterials: [Material] { dataVM.materials.filter { $0.roomId == room.id } }
    private var materialCost: Double { roomMaterials.reduce(0) { $0 + $1.totalCost } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: room.stage.color).opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: room.stage.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: room.stage.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(.bHeadline())
                        .foregroundColor(.bNavy)
                    BTag(text: room.stage.rawValue, color: Color(hex: room.stage.color), small: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.bNavy.opacity(0.3))
            }

            // Size info
            if room.area > 0 {
                HStack(spacing: 16) {
                    Label(String(format: "%.1f × %.1f m", room.width, room.length), systemImage: "ruler")
                        .font(.bCaption())
                        .foregroundColor(.bNavy.opacity(0.6))
                    Label(String(format: "%.1f m²", room.area), systemImage: "square.dashed")
                        .font(.bCaption())
                        .foregroundColor(.bNavy.opacity(0.6))
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Stage: \(room.stage.rawValue)")
                        .font(.bCaption())
                        .foregroundColor(.bNavy.opacity(0.5))
                    Spacer()
                    Text("\(Int(room.stage.progress * 100))%")
                        .font(.bCaption())
                        .foregroundColor(Color(hex: room.stage.color))
                }
                BProgressBar(value: room.stage.progress, color: Color(hex: room.stage.color), height: 6)
            }

            // Stats row
            HStack(spacing: 0) {
                miniStat(value: "\(roomTasks.count)", label: "Tasks", color: .bOrange)
                miniStat(value: "\(completedTasks)", label: "Done", color: .bGreen)
                miniStat(value: appState.formatAmount(materialCost), label: "Cost", color: .bRed)
            }
        }
        .padding(16)
        .bCardStyle()
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.bSubhead()).foregroundColor(color)
            Text(label).font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Room Detail

struct RoomDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State var room: Room
    @State private var showEdit = false
    @State private var selectedStage: RoomStage

    init(room: Room) {
        self._room = State(initialValue: room)
        self._selectedStage = State(initialValue: room.stage)
    }

    private var roomTasks: [RenovationTask] { dataVM.tasks.filter { $0.roomId == room.id } }
    private var roomMaterials: [Material] { dataVM.materials.filter { $0.roomId == room.id } }
    private var roomMeasurements: [RoomMeasurement] { dataVM.measurements(for: room.id) }

    var body: some View {
        ZStack {
            Color.bBG.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Stage Selector
                    stageSelector

                    // Room Info
                    roomInfoCard

                    // Tasks
                    if !roomTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            BSectionHeader(title: "Tasks (\(roomTasks.count))") {}
                            ForEach(roomTasks.prefix(5)) { task in
                                HStack(spacing: 10) {
                                    Button(action: { dataVM.toggleTaskComplete(task) }) {
                                        Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.status == .completed ? .bGreen : .bGrayBeige)
                                    }
                                    Text(task.title)
                                        .font(.bBody())
                                        .foregroundColor(.bNavy)
                                        .strikethrough(task.status == .completed)
                                    Spacer()
                                    BTag(text: task.priority.rawValue, color: Color(hex: task.priority.color), small: true)
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .bShadow(0.05)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Materials
                    if !roomMaterials.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            BSectionHeader(title: "Materials (\(roomMaterials.count))") {}
                            ForEach(roomMaterials.prefix(4)) { mat in
                                HStack {
                                    Image(systemName: mat.category.icon)
                                        .foregroundColor(Color(hex: mat.category.color))
                                        .frame(width: 32, height: 32)
                                        .background(Color(hex: mat.category.color).opacity(0.1))
                                        .cornerRadius(8)
                                    Text(mat.name).font(.bBody()).foregroundColor(.bNavy)
                                    Spacer()
                                    Text(appState.formatAmount(mat.totalCost)).font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .bShadow(0.05)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Measurements
                    if !roomMeasurements.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            BSectionHeader(title: "Measurements") {}
                            ForEach(roomMeasurements.prefix(4)) { m in
                                HStack {
                                    Image(systemName: m.type.icon).foregroundColor(.bBlue)
                                    Text(m.name).font(.bBody()).foregroundColor(.bNavy)
                                    Spacer()
                                    Text(String(format: "%.2f × %.2f \(m.unit.rawValue)", m.width, m.height))
                                        .font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .bShadow(0.05)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Notes
                    if !room.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(.bSubhead()).foregroundColor(.bNavy)
                            Text(room.notes).font(.bBody()).foregroundColor(.bNavy.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16).bCardStyle().padding(.horizontal, 20)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(room.name)
        .navigationBarItems(trailing: Button("Edit") { showEdit = true })
        .sheet(isPresented: $showEdit, onDismiss: {
            if let updated = DataStore.shared.data.rooms.first(where: { $0.id == room.id }) {
                room = updated
            }
        }) {
            EditRoomView(room: $room).environmentObject(dataVM)
        }
    }

    private var stageSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Renovation Stage").font(.bSubhead()).foregroundColor(.bNavy)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RoomStage.allCases, id: \.self) { stage in
                        Button(action: {
                            var updated = room
                            updated.stage = stage
                            room = updated
                            dataVM.updateRoom(updated)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: stage.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(room.stage == stage ? .white : Color(hex: stage.color))
                                Text(stage.rawValue)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(room.stage == stage ? .white : .bNavy.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(room.stage == stage ? Color(hex: stage.color) : Color(hex: stage.color).opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var roomInfoCard: some View {
        HStack(spacing: 0) {
            if room.area > 0 {
                StatBadge(value: String(format: "%.1f", room.area), label: "m² Area", color: .bBlue)
                StatBadge(value: String(format: "%.1f", room.height), label: "m Height", color: .bTeal)
                StatBadge(value: String(format: "%.1f", room.volume), label: "m³ Vol.", color: .bOrange)
            } else {
                Text("Add room dimensions in Edit").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16).bCardStyle().padding(.horizontal, 20)
    }
}

// MARK: - Add Room

struct AddRoomView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var width = ""
    @State private var length = ""
    @State private var height = "2.7"
    @State private var stage: RoomStage = .planning
    @State private var notes = ""
    @State private var errorMsg = ""

    let presets = ["Living Room", "Bedroom", "Kitchen", "Bathroom", "Hallway", "Office", "Dining Room", "Kids Room"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Presets
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(presets, id: \.self) { preset in
                                    Button(preset) { name = preset }
                                        .font(.bCaption())
                                        .foregroundColor(name == preset ? .white : .bNavy)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(name == preset ? Color.bBlue : Color.bGrayBeige)
                                        .cornerRadius(20)
                                }
                            }
                        }

                        BTextField(placeholder: "Room name *", text: $name, icon: "door.right.hand.open")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dimensions (optional)").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            HStack(spacing: 12) {
                                BTextField(placeholder: "Width (m)", text: $width, keyboardType: .decimalPad)
                                BTextField(placeholder: "Length (m)", text: $length, keyboardType: .decimalPad)
                                BTextField(placeholder: "Height (m)", text: $height, keyboardType: .decimalPad)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Stage").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(RoomStage.allCases, id: \.self) { s in
                                    Button(action: { stage = s }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: s.icon).font(.system(size: 14))
                                            Text(s.rawValue).font(.bCaption())
                                        }
                                        .foregroundColor(stage == s ? .white : .bNavy)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(stage == s ? Color(hex: s.color) : Color(hex: s.color).opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }

                        BTextField(placeholder: "Notes (optional)", text: $notes, icon: "note.text")

                        if !errorMsg.isEmpty {
                            Text(errorMsg).font(.bCaption()).foregroundColor(.bRed)
                        }

                        Button("Add Room") { save() }
                            .buttonStyle(BuildoraPrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMsg = "Please enter a room name."; return
        }
        dataVM.addRoom(
            name: name.trimmingCharacters(in: .whitespaces),
            width: Double(width) ?? 0,
            length: Double(length) ?? 0,
            height: Double(height) ?? 2.7,
            stage: stage,
            notes: notes
        )
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Room

struct EditRoomView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var room: Room

    @State private var name = ""
    @State private var width = ""
    @State private var length = ""
    @State private var height = ""
    @State private var stage: RoomStage = .planning
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Room name", text: $name, icon: "door.right.hand.open")
                        HStack(spacing: 12) {
                            BTextField(placeholder: "Width (m)", text: $width, keyboardType: .decimalPad)
                            BTextField(placeholder: "Length (m)", text: $length, keyboardType: .decimalPad)
                            BTextField(placeholder: "Height (m)", text: $height, keyboardType: .decimalPad)
                        }
                        Picker("Stage", selection: $stage) {
                            ForEach(RoomStage.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(14).background(Color.bSectionBG).cornerRadius(14)

                        BTextField(placeholder: "Notes", text: $notes, icon: "note.text")

                        Button("Save Changes") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Room")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear {
                name = room.name
                width = room.width > 0 ? String(format: "%.2f", room.width) : ""
                length = room.length > 0 ? String(format: "%.2f", room.length) : ""
                height = room.height > 0 ? String(format: "%.2f", room.height) : ""
                stage = room.stage
                notes = room.notes
            }
        }
    }

    private func save() {
        room.name = name
        room.width = Double(width) ?? room.width
        room.length = Double(length) ?? room.length
        room.height = Double(height) ?? room.height
        room.stage = stage
        room.notes = notes
        dataVM.updateRoom(room)
        presentationMode.wrappedValue.dismiss()
    }
}
