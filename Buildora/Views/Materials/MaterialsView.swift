import SwiftUI

struct MaterialsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var selectedCategory: MaterialCategory? = nil
    @State private var searchText = ""

    var filteredMaterials: [Material] {
        var base = dataVM.materials
        if let cat = selectedCategory { base = base.filter { $0.category == cat } }
        if !searchText.isEmpty { base = base.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return base
    }

    var totalCost: Double { filteredMaterials.reduce(0) { $0 + $1.totalCost } }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.bNavy.opacity(0.4))
                        TextField("Search materials…", text: $searchText).font(.bBody())
                    }
                    .padding(12).background(Color.white).cornerRadius(14).bShadow(0.05)
                    .padding(.horizontal, 20).padding(.vertical, 12)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button("All") {
                                withAnimation { selectedCategory = nil }
                            }
                            .font(.bCaption())
                            .foregroundColor(selectedCategory == nil ? .white : .bNavy)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selectedCategory == nil ? Color.bNavy : Color.bGrayBeige)
                            .cornerRadius(20)

                            ForEach(MaterialCategory.allCases, id: \.self) { cat in
                                let count = dataVM.materials.filter { $0.category == cat }.count
                                if count > 0 {
                                    Button(action: {
                                        withAnimation { selectedCategory = selectedCategory == cat ? nil : cat }
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: cat.icon).font(.system(size: 12))
                                            Text(cat.rawValue).font(.bCaption())
                                        }
                                        .foregroundColor(selectedCategory == cat ? .white : Color(hex: cat.color))
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(selectedCategory == cat ? Color(hex: cat.color) : Color(hex: cat.color).opacity(0.12))
                                        .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)

                    // Total cost bar
                    HStack {
                        Text("\(filteredMaterials.count) items")
                            .font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                        Spacer()
                        Text("Total: \(appState.formatAmount(totalCost))")
                            .font(.bSubhead()).foregroundColor(.bNavy)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 8)

                    // List
                    if filteredMaterials.isEmpty {
                        BEmptyState(
                            icon: "cube.box",
                            title: "No Materials",
                            subtitle: "Add materials to track costs",
                            buttonTitle: "Add Material",
                            onButton: { showAdd = true }
                        )
                    } else {
                        List {
                            ForEach(filteredMaterials) { material in
                                MaterialRow(material: material)
                                    .environmentObject(dataVM)
                                    .environmentObject(appState)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { i in dataVM.deleteMaterial(filteredMaterials[i]) }
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
                        BFAB(action: { showAdd = true }, color: .bRed)
                            .padding(.trailing, 24).padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Materials")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddMaterialView().environmentObject(dataVM).environmentObject(appState)
        }
    }
}

// MARK: - Material Row

struct MaterialRow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    let material: Material
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: material.category.color).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: material.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: material.category.color))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(material.name).font(.bBody()).foregroundColor(.bNavy).lineLimit(1)
                HStack(spacing: 8) {
                    BTag(text: material.category.rawValue, color: Color(hex: material.category.color), small: true)
                    Text("\(String(format: "%.1f", material.quantity)) \(material.unit)")
                        .font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(appState.formatAmount(material.totalCost))
                    .font(.bSubhead()).foregroundColor(.bNavy)
                Button(action: { dataVM.toggleMaterialStock(material) }) {
                    HStack(spacing: 3) {
                        Image(systemName: material.inStock ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                        Text(material.inStock ? "In Stock" : "Need")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(material.inStock ? .bGreen : .bOrange)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .bShadow(0.06)
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            MaterialDetailView(material: material).environmentObject(dataVM).environmentObject(appState)
        }
    }
}

// MARK: - Material Detail

struct MaterialDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let material: Material
    @State private var showEdit = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: material.category.color).opacity(0.12))
                                .frame(height: 120)
                            VStack(spacing: 8) {
                                Image(systemName: material.category.icon)
                                    .font(.system(size: 36))
                                    .foregroundColor(Color(hex: material.category.color))
                                Text(material.name).font(.bHeadline()).foregroundColor(.bNavy)
                                BTag(text: material.category.rawValue, color: Color(hex: material.category.color))
                            }
                        }
                        .padding(.horizontal, 20)

                        // Stats
                        HStack(spacing: 0) {
                            StatBadge(value: String(format: "%.1f", material.quantity), label: material.unit, color: .bBlue)
                            StatBadge(value: appState.formatAmount(material.pricePerUnit), label: "Per Unit", color: .bOrange)
                            StatBadge(value: appState.formatAmount(material.totalCost), label: "Total", color: .bRed)
                        }
                        .padding(16).bCardStyle().padding(.horizontal, 20)

                        // Details
                        VStack(spacing: 12) {
                            if !material.supplier.isEmpty {
                                detailRow(icon: "building.2", label: "Supplier", value: material.supplier)
                            }
                            detailRow(icon: "checkmark.circle", label: "In Stock", value: material.inStock ? "Yes" : "No")
                            if let roomId = material.roomId, let room = dataVM.rooms.first(where: { $0.id == roomId }) {
                                detailRow(icon: "door.right.hand.open", label: "Room", value: room.name)
                            }
                            if !material.notes.isEmpty {
                                detailRow(icon: "note.text", label: "Notes", value: material.notes)
                            }
                        }
                        .padding(16).bCardStyle().padding(.horizontal, 20)

                        Button(action: { dataVM.toggleMaterialStock(material); presentationMode.wrappedValue.dismiss() }) {
                            Label(material.inStock ? "Mark as Needed" : "Mark as In Stock",
                                  systemImage: material.inStock ? "xmark.circle" : "checkmark.circle.fill")
                        }
                        .buttonStyle(BuildoraPrimaryButtonStyle())
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Material")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Edit") { showEdit = true }
            )
        }
        .sheet(isPresented: $showEdit) {
            EditMaterialView(material: material).environmentObject(dataVM).environmentObject(appState)
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.bOrange).frame(width: 24)
            Text(label).font(.bBody()).foregroundColor(.bNavy.opacity(0.6))
            Spacer()
            Text(value).font(.bBody()).foregroundColor(.bNavy).multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Add Material

struct AddMaterialView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var category: MaterialCategory = .other
    @State private var quantity = "1"
    @State private var unit = "pcs"
    @State private var price = ""
    @State private var supplier = ""
    @State private var notes = ""
    @State private var selectedRoomId: UUID? = nil
    @State private var errorMsg = ""

    let units = ["pcs", "m", "m²", "m³", "kg", "L", "bags", "sheets", "rolls", "boxes"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Material name *", text: $name, icon: "cube.box")

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(MaterialCategory.allCases, id: \.self) { cat in
                                    Button(action: { category = cat }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: cat.icon).font(.system(size: 16))
                                            Text(cat.rawValue).font(.system(size: 10, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundColor(category == cat ? .white : Color(hex: cat.color))
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(category == cat ? Color(hex: cat.color) : Color(hex: cat.color).opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            BTextField(placeholder: "Quantity", text: $quantity, keyboardType: .decimalPad)
                            // Unit picker
                            Menu {
                                ForEach(units, id: \.self) { u in
                                    Button(u) { unit = u }
                                }
                            } label: {
                                HStack {
                                    Text(unit).font(.bBody()).foregroundColor(.bNavy)
                                    Image(systemName: "chevron.down").font(.system(size: 12)).foregroundColor(.bNavy.opacity(0.4))
                                }
                                .padding(14).background(Color.bSectionBG).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bGrayBeige, lineWidth: 1))
                            }
                        }

                        BTextField(placeholder: "Price per unit", text: $price, icon: "dollarsign.circle", keyboardType: .decimalPad)
                        BTextField(placeholder: "Supplier (optional)", text: $supplier, icon: "building.2")
                        BTextField(placeholder: "Notes (optional)", text: $notes, icon: "note.text")

                        // Room assignment
                        if !dataVM.rooms.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Assign to Room").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        Button("None") { selectedRoomId = nil }
                                            .font(.bCaption())
                                            .foregroundColor(selectedRoomId == nil ? .white : .bNavy)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(selectedRoomId == nil ? Color.bNavy : Color.bGrayBeige).cornerRadius(20)
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

                        if !errorMsg.isEmpty {
                            Text(errorMsg).font(.bCaption()).foregroundColor(.bRed)
                        }
                        Button("Add Material") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Material")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMsg = "Please enter a material name."; return
        }
        dataVM.addMaterial(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            quantity: Double(quantity) ?? 1,
            unit: unit,
            price: Double(price) ?? 0,
            supplier: supplier,
            notes: notes,
            roomId: selectedRoomId
        )
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Material

struct EditMaterialView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let material: Material

    @State private var name = ""
    @State private var category: MaterialCategory = .other
    @State private var quantity = ""
    @State private var unit = ""
    @State private var price = ""
    @State private var supplier = ""
    @State private var notes = ""
    @State private var inStock = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Name", text: $name, icon: "cube.box")
                        Picker("Category", selection: $category) {
                            ForEach(MaterialCategory.allCases, id: \.self) { c in Text(c.rawValue).tag(c) }
                        }.pickerStyle(MenuPickerStyle()).padding(14).background(Color.bSectionBG).cornerRadius(14)
                        HStack(spacing: 12) {
                            BTextField(placeholder: "Quantity", text: $quantity, keyboardType: .decimalPad)
                            BTextField(placeholder: "Unit", text: $unit)
                        }
                        BTextField(placeholder: "Price per unit", text: $price, icon: "dollarsign.circle", keyboardType: .decimalPad)
                        BTextField(placeholder: "Supplier", text: $supplier, icon: "building.2")
                        BTextField(placeholder: "Notes", text: $notes, icon: "note.text")
                        Toggle(isOn: $inStock) {
                            Label("In Stock", systemImage: "checkmark.circle").font(.bBody()).foregroundColor(.bNavy)
                        }.tint(.bGreen)
                        Button("Save Changes") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Material")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear {
                name = material.name; category = material.category
                quantity = String(format: "%.1f", material.quantity); unit = material.unit
                price = String(format: "%.2f", material.pricePerUnit); supplier = material.supplier
                notes = material.notes; inStock = material.inStock
            }
        }
    }

    private func save() {
        var updated = material
        updated.name = name; updated.category = category
        updated.quantity = Double(quantity) ?? material.quantity
        updated.unit = unit; updated.pricePerUnit = Double(price) ?? material.pricePerUnit
        updated.supplier = supplier; updated.notes = notes; updated.inStock = inStock
        dataVM.updateMaterial(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
