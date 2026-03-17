import SwiftUI

struct MeasurementsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var selectedRoomId: UUID? = nil

    var filteredMeasurements: [RoomMeasurement] {
        if let rid = selectedRoomId { return dataVM.measurements.filter { $0.roomId == rid } }
        return dataVM.measurements
    }

    var grouped: [(Room, [RoomMeasurement])] {
        dataVM.rooms.compactMap { room in
            let meas = dataVM.measurements(for: room.id)
            return meas.isEmpty ? nil : (room, meas)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Room filter
                    if !dataVM.rooms.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button("All Rooms") { withAnimation { selectedRoomId = nil } }
                                    .font(.bCaption())
                                    .foregroundColor(selectedRoomId == nil ? .white : .bNavy)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedRoomId == nil ? Color.bBlue : Color.bGrayBeige).cornerRadius(20)
                                ForEach(dataVM.rooms) { room in
                                    Button(room.name) { withAnimation { selectedRoomId = room.id } }
                                        .font(.bCaption())
                                        .foregroundColor(selectedRoomId == room.id ? .white : .bNavy)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(selectedRoomId == room.id ? Color.bBlue : Color.bGrayBeige).cornerRadius(20)
                                }
                            }.padding(.horizontal, 20)
                        }.padding(.vertical, 12)
                    }

                    if dataVM.measurements.isEmpty {
                        BEmptyState(icon: "ruler", title: "No Measurements", subtitle: "Start measuring your rooms", buttonTitle: "Add Measurement", onButton: { showAdd = true })
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                if selectedRoomId == nil {
                                    ForEach(grouped, id: \.0.id) { (room, measurements) in
                                        VStack(alignment: .leading, spacing: 10) {
                                            BSectionHeader(title: room.name) {}
                                            ForEach(measurements) { m in
                                                MeasurementRow(measurement: m).environmentObject(dataVM)
                                            }
                                        }
                                    }
                                } else {
                                    ForEach(filteredMeasurements) { m in
                                        MeasurementRow(measurement: m).environmentObject(dataVM)
                                    }
                                }
                                Spacer(minLength: 100)
                            }.padding(.horizontal, 20).padding(.top, 8)
                        }
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        BFAB(action: { showAdd = true }, color: .bBlue)
                            .padding(.trailing, 24).padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Measurements")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddMeasurementView().environmentObject(dataVM).environmentObject(appState)
        }
    }
}

// MARK: - Measurement Row

struct MeasurementRow: View {
    @EnvironmentObject var dataVM: DataViewModel
    let measurement: RoomMeasurement
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bBlue.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: measurement.type.icon)
                    .font(.system(size: 20)).foregroundColor(.bBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.name).font(.bBody()).foregroundColor(.bNavy)
                BTag(text: measurement.type.rawValue, color: .bBlue, small: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f × %.2f", measurement.width, measurement.height))
                    .font(.bSubhead()).foregroundColor(.bNavy)
                Text("\(measurement.unit.rawValue) · \(String(format: "%.2f", measurement.area)) \(measurement.unit.rawValue)²")
                    .font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
            }
        }
        .padding(14).background(Color.white).cornerRadius(16).bShadow(0.06)
        .onTapGesture { showEdit = true }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { dataVM.deleteMeasurement(measurement) } label: { Image(systemName: "trash") }
        }
        .sheet(isPresented: $showEdit) {
            EditMeasurementView(measurement: measurement).environmentObject(dataVM)
        }
    }
}

// MARK: - Add Measurement

struct AddMeasurementView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedRoomId: UUID? = nil
    @State private var type: MeasurementType = .wall
    @State private var name = ""
    @State private var width = ""
    @State private var height = ""
    @State private var unit: MeasurementUnit = .meters
    @State private var notes = ""
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Room selector
                        if !dataVM.rooms.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Room *").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(dataVM.rooms) { room in
                                            Button(room.name) { selectedRoomId = room.id }
                                                .font(.bCaption())
                                                .foregroundColor(selectedRoomId == room.id ? .white : .bNavy)
                                                .padding(.horizontal, 12).padding(.vertical, 8)
                                                .background(selectedRoomId == room.id ? Color.bBlue : Color.bGrayBeige).cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }

                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            HStack(spacing: 8) {
                                ForEach(MeasurementType.allCases, id: \.self) { t in
                                    Button(action: { type = t }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: t.icon).font(.system(size: 16))
                                            Text(t.rawValue).font(.system(size: 10, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundColor(type == t ? .white : .bBlue)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(type == t ? Color.bBlue : Color.bBlue.opacity(0.1)).cornerRadius(10)
                                    }
                                }
                            }
                        }

                        BTextField(placeholder: "Name (e.g. North Wall)", text: $name, icon: "ruler")

                        HStack(spacing: 12) {
                            BTextField(placeholder: "Width", text: $width, keyboardType: .decimalPad)
                            BTextField(placeholder: "Height", text: $height, keyboardType: .decimalPad)
                        }

                        // Unit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Unit").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            HStack(spacing: 8) {
                                ForEach(MeasurementUnit.allCases, id: \.self) { u in
                                    Button(u.rawValue) { unit = u }
                                        .font(.bCaption())
                                        .foregroundColor(unit == u ? .white : .bNavy)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(unit == u ? Color.bTeal : Color.bGrayBeige).cornerRadius(20)
                                }
                            }
                        }

                        BTextField(placeholder: "Notes (optional)", text: $notes, icon: "note.text")
                        if !errorMsg.isEmpty { Text(errorMsg).font(.bCaption()).foregroundColor(.bRed) }
                        Button("Add Measurement") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }.padding(20)
                }
            }
            .navigationTitle("New Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear { if selectedRoomId == nil { selectedRoomId = dataVM.rooms.first?.id } }
        }
    }

    private func save() {
        guard let rid = selectedRoomId else { errorMsg = "Please select a room."; return }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Please enter a name."; return }
        guard let w = Double(width), let h = Double(height), w > 0 || h > 0 else { errorMsg = "Please enter valid dimensions."; return }
        dataVM.addMeasurement(roomId: rid, type: type, name: name, width: w, height: h, unit: unit, notes: notes)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Measurement

struct EditMeasurementView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let measurement: RoomMeasurement

    @State private var type: MeasurementType = .wall
    @State private var name = ""
    @State private var width = ""
    @State private var height = ""
    @State private var unit: MeasurementUnit = .meters
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Picker("Type", selection: $type) {
                            ForEach(MeasurementType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                        }.pickerStyle(SegmentedPickerStyle())
                        BTextField(placeholder: "Name", text: $name, icon: "ruler")
                        HStack(spacing: 12) {
                            BTextField(placeholder: "Width", text: $width, keyboardType: .decimalPad)
                            BTextField(placeholder: "Height", text: $height, keyboardType: .decimalPad)
                        }
                        Picker("Unit", selection: $unit) {
                            ForEach(MeasurementUnit.allCases, id: \.self) { u in Text(u.rawValue).tag(u) }
                        }.pickerStyle(SegmentedPickerStyle())
                        BTextField(placeholder: "Notes", text: $notes, icon: "note.text")
                        Button("Save Changes") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }.padding(20)
                }
            }
            .navigationTitle("Edit Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear {
                type = measurement.type; name = measurement.name
                width = String(format: "%.2f", measurement.width); height = String(format: "%.2f", measurement.height)
                unit = measurement.unit; notes = measurement.notes
            }
        }
    }

    private func save() {
        var updated = measurement
        updated.type = type; updated.name = name
        updated.width = Double(width) ?? measurement.width; updated.height = Double(height) ?? measurement.height
        updated.unit = unit; updated.notes = notes
        dataVM.updateMeasurement(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
