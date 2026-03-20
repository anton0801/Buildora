import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var selectedRole: ContactRole? = nil
    @State private var searchText = ""

    var filteredContacts: [Contact] {
        var base = dataVM.contacts
        if let role = selectedRole { base = base.filter { $0.role == role } }
        if !searchText.isEmpty { base = base.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return base
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.bNavy.opacity(0.4))
                        TextField("Search contacts…", text: $searchText).font(.bBody())
                    }
                    .padding(12).background(Color.white).cornerRadius(14).bShadow(0.05)
                    .padding(.horizontal, 20).padding(.vertical, 12)

                    // Role filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button("All") { withAnimation { selectedRole = nil } }
                                .font(.bCaption())
                                .foregroundColor(selectedRole == nil ? .white : .bNavy)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selectedRole == nil ? Color.bNavy : Color.bGrayBeige).cornerRadius(20)
                            ForEach(ContactRole.allCases, id: \.self) { role in
                                let count = dataVM.contacts.filter { $0.role == role }.count
                                if count > 0 {
                                    Button(action: { withAnimation { selectedRole = selectedRole == role ? nil : role } }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: role.icon).font(.system(size: 11))
                                            Text(role.rawValue).font(.bCaption())
                                        }
                                        .foregroundColor(selectedRole == role ? .white : Color(hex: role.color))
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(selectedRole == role ? Color(hex: role.color) : Color(hex: role.color).opacity(0.12)).cornerRadius(20)
                                    }
                                }
                            }
                        }.padding(.horizontal, 20)
                    }.padding(.bottom, 12)

                    if filteredContacts.isEmpty {
                        BEmptyState(icon: "person.crop.circle.badge.plus", title: "No Contacts", subtitle: "Save contacts for your renovation team", buttonTitle: "Add Contact", onButton: { showAdd = true })
                    } else {
                        List {
                            ForEach(filteredContacts) { contact in
                                ContactRow(contact: contact).environmentObject(dataVM).environmentObject(appState)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { i in dataVM.deleteContact(filteredContacts[i]) }
                            }
                            Spacer().frame(height: 80).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                        .listStyle(PlainListStyle())
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        BFAB(action: { showAdd = true }, color: .bOrange)
                            .padding(.trailing, 24).padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddContactView().environmentObject(dataVM).environmentObject(appState)
        }
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    let contact: Contact
    @State private var showDetail = false
    @State private var showAddEntry = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: contact.role.color).opacity(0.2))
                        .frame(width: 52, height: 52)
                    Text(String(contact.name.prefix(1)))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: contact.role.color))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(contact.name).font(.bSubhead()).foregroundColor(.bNavy)
                    HStack(spacing: 6) {
                        Image(systemName: contact.role.icon).font(.system(size: 11)).foregroundColor(Color(hex: contact.role.color))
                        BTag(text: contact.role.rawValue, color: Color(hex: contact.role.color), small: true)
                        if contact.rating > 0 {
                            HStack(spacing: 1) {
                                ForEach(1...5, id: \.self) { s in
                                    Image(systemName: s <= contact.rating ? "star.fill" : "star")
                                        .font(.system(size: 8))
                                        .foregroundColor(s <= contact.rating ? .bYellow : .bGrayBeige)
                                }
                            }
                        }
                    }
                    if !contact.phone.isEmpty {
                        Text(contact.phone).font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                    }
                }

                Spacer()

                // Quick action buttons
                HStack(spacing: 8) {
                    if !contact.phone.isEmpty {
                        quickBtn(icon: "phone.fill", color: .bGreen) {
                            if let url = URL(string: "tel:\(contact.phone.filter { $0.isNumber || $0 == "+" })") {
                                UIApplication.shared.open(url)
                            }
                        }
                        quickBtn(icon: "message.fill", color: .bBlue) {
                            if let url = URL(string: "sms:\(contact.phone.filter { $0.isNumber || $0 == "+" })") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    quickBtn(icon: "plus.circle.fill", color: .bOrange) {
                        showAddEntry = true
                    }
                }
            }
        }
        .padding(14).background(Color.white).cornerRadius(16).bShadow(0.06)
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            ContactDetailView(contact: contact).environmentObject(dataVM).environmentObject(appState)
        }
        .sheet(isPresented: $showAddEntry) {
            AddJobLogEntryView(contact: contact).environmentObject(dataVM).environmentObject(appState)
        }
    }

    private func quickBtn(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(9)
        }
    }
}

// MARK: - Contact Detail

struct ContactDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let contact: Contact
    @State private var showEdit = false
    @State private var rating: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Avatar card
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color(hex: contact.role.color), Color(hex: contact.role.color).opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 90, height: 90)
                                Text(String(contact.name.prefix(2)))
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Text(contact.name).font(.bHeadline()).foregroundColor(.bNavy)
                            BTag(text: contact.role.rawValue, color: Color(hex: contact.role.color))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20).bCardStyle().padding(.horizontal, 20)

                        // Contact actions
                        HStack(spacing: 12) {
                            if !contact.phone.isEmpty {
                                contactAction(icon: "phone.fill", label: "Call", color: .bGreen) {
                                    if let url = URL(string: "tel:\(contact.phone.filter { $0.isNumber || $0 == "+" })") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                contactAction(icon: "message.fill", label: "Message", color: .bBlue) {
                                    if let url = URL(string: "sms:\(contact.phone.filter { $0.isNumber || $0 == "+" })") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                            if !contact.email.isEmpty {
                                contactAction(icon: "envelope.fill", label: "Email", color: .bOrange) {
                                    if let url = URL(string: "mailto:\(contact.email)") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Info
                        VStack(spacing: 12) {
                            if !contact.phone.isEmpty {
                                infoRow(icon: "phone", label: "Phone", value: contact.phone)
                            }
                            if !contact.email.isEmpty {
                                infoRow(icon: "envelope", label: "Email", value: contact.email)
                            }
                            if !contact.notes.isEmpty {
                                infoRow(icon: "note.text", label: "Notes", value: contact.notes)
                            }
                            infoRow(icon: "calendar", label: "Added", value: contact.createdAt.formatted(.dateTime.day().month().year()))
                        }
                        .padding(16).bCardStyle().padding(.horizontal, 20)

                        // Job Log Section
                        JobLogSection(contact: contact, rating: $rating)
                            .environmentObject(dataVM)
                            .environmentObject(appState)
                            .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("Contact")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Edit") { showEdit = true }
            )
            .onAppear { rating = contact.rating }
            .onChange(of: rating) { newRating in
                var updated = contact
                updated.rating = newRating
                dataVM.updateContact(updated)
            }
        }
        .sheet(isPresented: $showEdit) {
            EditContactView(contact: contact).environmentObject(dataVM).environmentObject(appState)
        }
    }

    private func contactAction(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 22)).foregroundColor(.white)
                    .frame(width: 52, height: 52).background(color).cornerRadius(16)
                Text(label).font(.bCaption()).foregroundColor(.bNavy)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.bOrange).frame(width: 24)
            Text(label).font(.bBody()).foregroundColor(.bNavy.opacity(0.6))
            Spacer()
            Text(value).font(.bBody()).foregroundColor(.bNavy).multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Add Contact

struct AddContactView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var role: ContactRole = .master
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Full name *", text: $name, icon: "person")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(ContactRole.allCases, id: \.self) { r in
                                    Button(action: { role = r }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: r.icon).font(.system(size: 18))
                                            Text(r.rawValue).font(.system(size: 11, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundColor(role == r ? .white : Color(hex: r.color))
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(role == r ? Color(hex: r.color) : Color(hex: r.color).opacity(0.1)).cornerRadius(12)
                                    }
                                }
                            }
                        }

                        BTextField(placeholder: "Phone number", text: $phone, icon: "phone", keyboardType: .phonePad)
                        BTextField(placeholder: "Email address", text: $email, icon: "envelope", keyboardType: .emailAddress)
                        BTextField(placeholder: "Notes (optional)", text: $notes, icon: "note.text")

                        if !errorMsg.isEmpty { Text(errorMsg).font(.bCaption()).foregroundColor(.bRed) }
                        Button("Add Contact") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }.padding(20)
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Please enter a name."; return }
        dataVM.addContact(name: name.trimmingCharacters(in: .whitespaces), role: role, phone: phone, email: email, notes: notes)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Contact

struct EditContactView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let contact: Contact

    @State private var name = ""
    @State private var role: ContactRole = .master
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Full name", text: $name, icon: "person")
                        Picker("Role", selection: $role) {
                            ForEach(ContactRole.allCases, id: \.self) { r in Text(r.rawValue).tag(r) }
                        }.pickerStyle(MenuPickerStyle()).padding(14).background(Color.bSectionBG).cornerRadius(14)
                        BTextField(placeholder: "Phone", text: $phone, icon: "phone", keyboardType: .phonePad)
                        BTextField(placeholder: "Email", text: $email, icon: "envelope", keyboardType: .emailAddress)
                        BTextField(placeholder: "Notes", text: $notes, icon: "note.text")
                        Button("Save Changes") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }.padding(20)
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear { name = contact.name; role = contact.role; phone = contact.phone; email = contact.email; notes = contact.notes }
        }
    }

    private func save() {
        var updated = contact
        updated.name = name; updated.role = role; updated.phone = phone; updated.email = email; updated.notes = notes
        dataVM.updateContact(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
