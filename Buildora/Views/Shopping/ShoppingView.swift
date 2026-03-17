import SwiftUI

struct ShoppingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var selectedSection: ShoppingCategory? = nil

    var grouped: [(ShoppingCategory, [ShoppingItem])] {
        let order: [ShoppingCategory] = [.urgent, .thisWeek, .later, .bought]
        return order.compactMap { cat in
            var items = dataVM.shoppingItems.filter { $0.category == cat }
            if !items.isEmpty { return (cat, items) }
            return nil
        }
    }

    var totalEstimated: Double { dataVM.shoppingItems.filter { !$0.bought }.reduce(0) { $0 + $1.estimatedPrice * $1.quantity } }
    var totalSpent: Double { dataVM.shoppingItems.filter { $0.bought }.reduce(0) { $0 + ($1.actualPrice ?? $1.estimatedPrice) * $1.quantity } }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Summary
                    HStack(spacing: 0) {
                        StatBadge(value: "\(dataVM.shoppingItems.filter { !$0.bought }.count)", label: "To Buy", color: .bOrange)
                        StatBadge(value: "\(dataVM.shoppingItems.filter { $0.bought }.count)", label: "Bought", color: .bGreen)
                        StatBadge(value: appState.formatAmount(totalEstimated), label: "Estimated", color: .bBlue)
                    }
                    .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 12)

                    if dataVM.shoppingItems.isEmpty {
                        BEmptyState(icon: "cart", title: "Shopping List Empty", subtitle: "Add items you need to buy", buttonTitle: "Add Item", onButton: { showAdd = true })
                    } else {
                        List {
                            ForEach(grouped, id: \.0) { (cat, items) in
                                Section(header: shoppingHeader(cat)) {
                                    ForEach(items) { item in
                                        ShoppingItemRow(item: item)
                                            .environmentObject(dataVM)
                                            .environmentObject(appState)
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 3, leading: 20, bottom: 3, trailing: 20))
                                    }
                                    .onDelete { indexSet in
                                        indexSet.forEach { i in dataVM.deleteShoppingItem(items[i]) }
                                    }
                                }
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
                        BFAB(action: { showAdd = true }, color: .bTeal)
                            .padding(.trailing, 24).padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddShoppingItemView().environmentObject(dataVM).environmentObject(appState)
        }
    }

    private func shoppingHeader(_ cat: ShoppingCategory) -> some View {
        HStack(spacing: 8) {
            Image(systemName: cat.icon).font(.system(size: 14)).foregroundColor(Color(hex: cat.color))
            Text(cat.rawValue).font(.bSubhead()).foregroundColor(.bNavy)
            Spacer()
            let count = dataVM.shoppingItems.filter { $0.category == cat }.count
            Text("\(count)").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shopping Item Row

struct ShoppingItemRow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    let item: ShoppingItem
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dataVM.toggleItemBought(item)
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(item.bought ? Color.bGreen : Color(hex: item.category.color), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if item.bought {
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundColor(.bGreen)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.bBody()).foregroundColor(item.bought ? .bNavy.opacity(0.4) : .bNavy)
                    .strikethrough(item.bought).lineLimit(1)
                HStack(spacing: 8) {
                    Text("\(String(format: "%.0f", item.quantity)) \(item.unit)")
                        .font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    if !item.store.isEmpty {
                        Text("• \(item.store)").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(appState.formatAmount(item.estimatedPrice * item.quantity))
                    .font(.bBody()).foregroundColor(.bNavy)
                BTag(text: item.category.rawValue, color: Color(hex: item.category.color), small: true)
            }
        }
        .padding(14).background(item.bought ? Color.bGreen.opacity(0.05) : Color.white)
        .cornerRadius(14).bShadow(0.06)
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            ShoppingItemDetailView(item: item).environmentObject(dataVM).environmentObject(appState)
        }
    }
}

// MARK: - Shopping Item Detail

struct ShoppingItemDetailView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let item: ShoppingItem
    @State private var showEdit = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: item.category.color).opacity(0.12)).frame(height: 110)
                            VStack(spacing: 8) {
                                Image(systemName: item.category.icon).font(.system(size: 34))
                                    .foregroundColor(Color(hex: item.category.color))
                                Text(item.name).font(.bHeadline()).foregroundColor(.bNavy)
                            }
                        }.padding(.horizontal, 20)

                        HStack(spacing: 0) {
                            StatBadge(value: String(format: "%.0f \(item.unit)", item.quantity), label: "Quantity", color: .bBlue)
                            StatBadge(value: appState.formatAmount(item.estimatedPrice), label: "Est./Unit", color: .bOrange)
                            StatBadge(value: appState.formatAmount(item.estimatedPrice * item.quantity), label: "Total Est.", color: .bRed)
                        }.padding(16).bCardStyle().padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            if !item.store.isEmpty {
                                HStack { Image(systemName: "bag").foregroundColor(.bOrange).frame(width:24); Text("Store").font(.bBody()).foregroundColor(.bNavy.opacity(0.6)); Spacer(); Text(item.store).font(.bBody()).foregroundColor(.bNavy) }
                            }
                            if !item.notes.isEmpty {
                                HStack { Image(systemName: "note.text").foregroundColor(.bOrange).frame(width:24); Text("Notes").font(.bBody()).foregroundColor(.bNavy.opacity(0.6)); Spacer(); Text(item.notes).font(.bBody()).foregroundColor(.bNavy) }
                            }
                        }.padding(16).bCardStyle().padding(.horizontal, 20)

                        Button(action: { dataVM.toggleItemBought(item); presentationMode.wrappedValue.dismiss() }) {
                            Label(item.bought ? "Mark as To Buy" : "Mark as Bought",
                                  systemImage: item.bought ? "cart.badge.minus" : "cart.badge.plus")
                        }.buttonStyle(BuildoraPrimaryButtonStyle()).padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("Item Detail")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Edit") { showEdit = true }
            )
        }
        .sheet(isPresented: $showEdit) {
            EditShoppingItemView(item: item).environmentObject(dataVM).environmentObject(appState)
        }
    }
}

// MARK: - Add Shopping Item

struct AddShoppingItemView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var category: ShoppingCategory = .thisWeek
    @State private var quantity = "1"
    @State private var unit = "pcs"
    @State private var price = ""
    @State private var store = ""
    @State private var notes = ""
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Item name *", text: $name, icon: "cart")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("When to buy").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            HStack(spacing: 8) {
                                ForEach([ShoppingCategory.urgent, .thisWeek, .later], id: \.self) { cat in
                                    Button(action: { category = cat }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: cat.icon).font(.system(size: 14))
                                            Text(cat.rawValue).font(.system(size: 11, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundColor(category == cat ? .white : Color(hex: cat.color))
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(category == cat ? Color(hex: cat.color) : Color(hex: cat.color).opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            BTextField(placeholder: "Qty", text: $quantity, keyboardType: .decimalPad)
                            BTextField(placeholder: "Unit", text: $unit)
                        }
                        BTextField(placeholder: "Estimated price (per unit)", text: $price, icon: "dollarsign.circle", keyboardType: .decimalPad)
                        BTextField(placeholder: "Store (optional)", text: $store, icon: "bag")
                        BTextField(placeholder: "Notes (optional)", text: $notes, icon: "note.text")

                        if !errorMsg.isEmpty { Text(errorMsg).font(.bCaption()).foregroundColor(.bRed) }
                        Button("Add to List") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }.padding(20)
                }
            }
            .navigationTitle("Add to Shopping")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Please enter item name."; return }
        dataVM.addShoppingItem(name: name.trimmingCharacters(in: .whitespaces), category: category, quantity: Double(quantity) ?? 1, unit: unit, price: Double(price) ?? 0, store: store, notes: notes)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Shopping Item

struct EditShoppingItemView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let item: ShoppingItem

    @State private var name = ""
    @State private var category: ShoppingCategory = .later
    @State private var quantity = ""
    @State private var unit = ""
    @State private var price = ""
    @State private var store = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Item name", text: $name, icon: "cart")
                        Picker("Category", selection: $category) {
                            ForEach(ShoppingCategory.allCases, id: \.self) { c in Text(c.rawValue).tag(c) }
                        }.pickerStyle(SegmentedPickerStyle())
                        HStack(spacing: 12) {
                            BTextField(placeholder: "Quantity", text: $quantity, keyboardType: .decimalPad)
                            BTextField(placeholder: "Unit", text: $unit)
                        }
                        BTextField(placeholder: "Price per unit", text: $price, icon: "dollarsign.circle", keyboardType: .decimalPad)
                        BTextField(placeholder: "Store", text: $store, icon: "bag")
                        BTextField(placeholder: "Notes", text: $notes, icon: "note.text")
                        Button("Save Changes") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }.padding(20)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear {
                name = item.name; category = item.category
                quantity = String(format: "%.0f", item.quantity); unit = item.unit
                price = String(format: "%.2f", item.estimatedPrice); store = item.store; notes = item.notes
            }
        }
    }

    private func save() {
        var updated = item
        updated.name = name; updated.category = category
        updated.quantity = Double(quantity) ?? item.quantity; updated.unit = unit
        updated.estimatedPrice = Double(price) ?? item.estimatedPrice
        updated.store = store; updated.notes = notes
        dataVM.updateShoppingItem(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
