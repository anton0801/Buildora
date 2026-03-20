import SwiftUI
import PhotosUI

// MARK: - Star Rating View

struct StarRatingView: View {
    @Binding var rating: Int
    var interactive: Bool = true
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(star <= rating ? .bYellow : .bGrayBeige)
                    .onTapGesture {
                        guard interactive else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = (rating == star) ? 0 : star
                        }
                    }
            }
        }
    }
}

// MARK: - Job Log Summary Bar

struct JobLogSummaryBar: View {
    let entries: [JobLogEntry]
    let rating: Int

    private var totalPaid: Double { entries.reduce(0) { $0 + $1.amountPaid } }
    private var lastSeen: String {
        guard let latest = entries.max(by: { $0.date < $1.date }) else { return "—" }
        return latest.date.formatted(.dateTime.day().month(.abbreviated))
    }

    var body: some View {
        HStack(spacing: 0) {
            summaryCell(value: "\(entries.count)", label: "Jobs", color: .bBlue)
            summaryCell(value: String(format: "$%.0f", totalPaid), label: "Total Paid", color: .bGreen)
            summaryCell(value: lastSeen, label: "Last Seen", color: .bOrange)
        }
        .padding(12)
        .background(Color.bSectionBG)
        .cornerRadius(14)
    }

    private func summaryCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.bSubhead())
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.bCaption())
                .foregroundColor(.bNavy.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Job Log Entry Row

struct JobLogEntryRow: View {
    let entry: JobLogEntry
    let roomName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Date badge
                VStack(spacing: 2) {
                    Text(entry.date.formatted(.dateTime.day()))
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.bNavy)
                    Text(entry.date.formatted(.dateTime.month(.abbreviated)))
                        .font(.bCaption())
                        .foregroundColor(.bNavy.opacity(0.5))
                }
                .frame(width: 40)
                .padding(.vertical, 8)
                .background(Color.bSectionBG)
                .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    if !entry.tasksDone.isEmpty {
                        Text(entry.tasksDone)
                            .font(.bBody())
                            .foregroundColor(.bNavy)
                            .lineLimit(2)
                    }
                    HStack(spacing: 10) {
                        if let room = roomName {
                            Label(room, systemImage: "door.right.hand.open")
                                .font(.bCaption())
                                .foregroundColor(.bBlue)
                        }
                        if entry.hoursWorked > 0 {
                            Label(String(format: "%.1fh", entry.hoursWorked), systemImage: "clock")
                                .font(.bCaption())
                                .foregroundColor(.bNavy.opacity(0.55))
                        }
                    }
                }

                Spacer()

                if entry.amountPaid > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "$%.0f", entry.amountPaid))
                            .font(.bSubhead())
                            .foregroundColor(.bGreen)
                        Text("paid")
                            .font(.bCaption())
                            .foregroundColor(.bNavy.opacity(0.4))
                    }
                }
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.bCaption())
                    .foregroundColor(.bNavy.opacity(0.55))
                    .lineLimit(2)
                    .padding(.leading, 48)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .bShadow(0.05)
    }
}

// MARK: - Job Log Section (embedded in ContactDetailView)

struct JobLogSection: View {
    @EnvironmentObject var dataVM: DataViewModel
    @EnvironmentObject var appState: AppState

    let contact: Contact
    @Binding var rating: Int
    @State private var showAdd = false

    private var entries: [JobLogEntry] {
        dataVM.jobLogEntries(for: contact.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Summary
            JobLogSummaryBar(entries: entries, rating: rating)

            // Star rating (interactive)
            VStack(spacing: 6) {
                Text("Rating")
                    .font(.bCaption())
                    .foregroundColor(.bNavy.opacity(0.5))
                StarRatingView(rating: $rating)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.bSectionBG)
            .cornerRadius(14)

            // Header
            HStack {
                Text("Job Log")
                    .font(.bHeadline())
                    .foregroundColor(.bNavy)
                Spacer()
                Button(action: { showAdd = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Entry")
                    }
                    .font(.bCaption())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.bOrange)
                    .cornerRadius(20)
                }
            }

            if entries.isEmpty {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.bGrayBeige)
                        .font(.system(size: 24))
                    Text("No job entries yet")
                        .font(.bBody())
                        .foregroundColor(.bNavy.opacity(0.4))
                    Spacer()
                }
                .padding(16)
                .background(Color.bSectionBG)
                .cornerRadius(14)
            } else {
                VStack(spacing: 8) {
                    ForEach(entries) { entry in
                        let roomName = dataVM.rooms.first(where: { $0.id == entry.roomId })?.name
                        JobLogEntryRow(entry: entry, roomName: roomName)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    dataVM.deleteJobLogEntry(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddJobLogEntryView(contact: contact)
                .environmentObject(dataVM)
                .environmentObject(appState)
        }
    }
}

// MARK: - Add Job Log Entry View

struct AddJobLogEntryView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    let contact: Contact

    @State private var date = Date()
    @State private var tasksDone = ""
    @State private var hoursWorked = ""
    @State private var amountPaid = ""
    @State private var selectedRoomId: UUID? = nil
    @State private var notes = ""
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Date picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .padding(14)
                                .background(Color.bSectionBG)
                                .cornerRadius(14)
                        }

                        BTextField(placeholder: "Tasks done *", text: $tasksDone, icon: "checkmark.circle")
                        BTextField(placeholder: "Hours worked", text: $hoursWorked, icon: "clock", keyboardType: .decimalPad)
                        BTextField(placeholder: "Amount paid", text: $amountPaid, icon: "dollarsign.circle", keyboardType: .decimalPad)

                        // Room picker
                        if !dataVM.rooms.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Linked Room (optional)").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                Picker("Room", selection: $selectedRoomId) {
                                    Text("None").tag(Optional<UUID>(nil))
                                    ForEach(dataVM.rooms) { room in
                                        Text(room.name).tag(Optional(room.id))
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(14)
                                .background(Color.bSectionBG)
                                .cornerRadius(14)
                            }
                        }

                        BTextField(placeholder: "Notes (optional)", text: $notes, icon: "note.text")

                        if !errorMsg.isEmpty {
                            Text(errorMsg).font(.bCaption()).foregroundColor(.bRed)
                        }

                        Button("Save Entry") { save() }
                            .buttonStyle(BuildoraPrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Job Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }

    private func save() {
        guard !tasksDone.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMsg = "Please describe what was done."
            return
        }
        dataVM.addJobLogEntry(
            contactId: contact.id,
            date: date,
            tasksDone: tasksDone.trimmingCharacters(in: .whitespaces),
            hoursWorked: Double(hoursWorked) ?? 0,
            amountPaid: Double(amountPaid) ?? 0,
            roomId: selectedRoomId,
            notes: notes,
            imageData: nil
        )
        presentationMode.wrappedValue.dismiss()
    }
}
