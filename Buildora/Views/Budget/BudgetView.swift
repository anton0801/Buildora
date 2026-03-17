import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var selectedCategory: ExpenseCategory? = nil

    var filteredExpenses: [BudgetExpense] {
        if let cat = selectedCategory { return dataVM.expenses.filter { $0.category == cat } }
        return dataVM.expenses
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Budget Summary Card
                        budgetSummaryCard

                        // Category breakdown
                        categoryBreakdownSection

                        // Expense filter
                        categoryFilterRow

                        // Expenses list
                        expenseListSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
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
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddExpenseView().environmentObject(dataVM).environmentObject(appState)
        }
    }

    // MARK: - Budget Summary Card

    private var budgetSummaryCard: some View {
        VStack(spacing: 16) {
            // Main numbers
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Budget")
                        .font(.bCaption()).foregroundColor(.white.opacity(0.8))
                    Text(appState.formatAmount(dataVM.totalBudget))
                        .font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.bCaption()).foregroundColor(.white.opacity(0.8))
                    Text(appState.formatAmount(max(dataVM.remainingBudget, 0)))
                        .font(.bHeadline()).foregroundColor(.white)
                    if dataVM.remainingBudget < 0 {
                        BTag(text: "Over Budget!", color: .white)
                    }
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Spent: \(appState.formatAmount(dataVM.totalSpent))")
                        .font(.bCaption()).foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(dataVM.budgetProgress * 100))%")
                        .font(.bCaption()).foregroundColor(.white)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dataVM.budgetProgress > 0.9 ? Color.bRed : Color.white)
                            .frame(width: geo.size.width * CGFloat(dataVM.budgetProgress), height: 8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: dataVM.budgetProgress)
                    }
                }.frame(height: 8)
            }

            // Planned vs Unexpected
            HStack(spacing: 0) {
                budgetStatItem("Planned", value: appState.formatAmount(dataVM.plannedCosts))
                budgetStatItem("Unexpected", value: appState.formatAmount(dataVM.unexpectedCosts))
                budgetStatItem("Expenses", value: "\(dataVM.expenses.count)")
            }
        }
        .padding(20)
        .background(LinearGradient.bBlueTeal)
        .cornerRadius(24)
        .bShadow(0.2)
    }

    private func budgetStatItem(_ label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.bSubhead()).foregroundColor(.white).minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.bCaption()).foregroundColor(.white.opacity(0.7))
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "By Category") {}

            let breakdown = dataVM.spentByCategory()
            if breakdown.isEmpty {
                Text("No expenses yet.").font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).bCardStyle()
            } else {
                VStack(spacing: 10) {
                    ForEach(breakdown.prefix(5), id: \.0) { (cat, amount) in
                        categoryBar(category: cat, amount: amount, max: breakdown.first?.1 ?? 1)
                    }
                }
                .padding(16).bCardStyle()
            }
        }
    }

    private func categoryBar(category: ExpenseCategory, amount: Double, max: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: category.color))
                .frame(width: 32, height: 32)
                .background(Color(hex: category.color).opacity(0.12))
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.rawValue).font(.bBody()).foregroundColor(.bNavy)
                    Spacer()
                    Text(appState.formatAmount(amount)).font(.bCaption()).foregroundColor(.bNavy.opacity(0.7))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.bGrayBeige).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: category.color))
                            .frame(width: geo.size.width * CGFloat(amount / max), height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: amount)
                    }
                }.frame(height: 6)
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") { withAnimation { selectedCategory = nil } }
                    .font(.bCaption())
                    .foregroundColor(selectedCategory == nil ? .white : .bNavy)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(selectedCategory == nil ? Color.bNavy : Color.bGrayBeige).cornerRadius(20)

                ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                    let count = dataVM.expenses.filter { $0.category == cat }.count
                    if count > 0 {
                        Button(action: { withAnimation { selectedCategory = selectedCategory == cat ? nil : cat } }) {
                            HStack(spacing: 5) {
                                Image(systemName: cat.icon).font(.system(size: 11))
                                Text(cat.rawValue).font(.bCaption())
                            }
                            .foregroundColor(selectedCategory == cat ? .white : Color(hex: cat.color))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selectedCategory == cat ? Color(hex: cat.color) : Color(hex: cat.color).opacity(0.12)).cornerRadius(20)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Expense List

    private var expenseListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BSectionHeader(title: "Expenses (\(filteredExpenses.count))") {}

            if filteredExpenses.isEmpty {
                BEmptyState(icon: "creditcard", title: "No expenses yet", subtitle: "Track your renovation spending", buttonTitle: "Add Expense", onButton: { showAdd = true })
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredExpenses) { expense in
                        ExpenseRow(expense: expense)
                            .environmentObject(dataVM)
                            .environmentObject(appState)
                    }
                }
            }
        }
    }
}

// MARK: - Expense Row

struct ExpenseRow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    let expense: BudgetExpense
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: expense.category.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: expense.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: expense.category.color))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.expenseDescription.isEmpty ? expense.category.rawValue : expense.expenseDescription)
                    .font(.bBody()).foregroundColor(.bNavy).lineLimit(1)
                HStack(spacing: 8) {
                    Text(expense.date, style: .date).font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                    BTag(text: expense.category.rawValue, color: Color(hex: expense.category.color), small: true)
                    if expense.isUnexpected { BTag(text: "Unexpected", color: .bRed, small: true) }
                }
            }
            Spacer()
            Text(appState.formatAmount(expense.amount)).font(.bSubhead()).foregroundColor(.bNavy)
        }
        .padding(14).background(Color.white).cornerRadius(16).bShadow(0.06)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { dataVM.deleteExpense(expense) } label: {
                Image(systemName: "trash")
            }
            Button { showEdit = true } label: {
                Image(systemName: "pencil")
            }.tint(.bBlue)
        }
        .sheet(isPresented: $showEdit) {
            EditExpenseView(expense: expense).environmentObject(dataVM).environmentObject(appState)
        }
    }
}

// MARK: - Add Expense

struct AddExpenseView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var category: ExpenseCategory = .materials
    @State private var amount = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var isUnexpected = false
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Amount
                        VStack(spacing: 8) {
                            Text("Amount").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                Text(appState.currencySymbol).font(.bTitle()).foregroundColor(.bNavy.opacity(0.4))
                                TextField("0", text: $amount)
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .foregroundColor(.bNavy)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(16).bCardStyle()
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category").font(.bCaption()).foregroundColor(.bNavy.opacity(0.6))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                                    Button(action: { category = cat }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: cat.icon).font(.system(size: 16))
                                            Text(cat.rawValue).font(.bCaption())
                                            Spacer()
                                        }
                                        .foregroundColor(category == cat ? .white : Color(hex: cat.color))
                                        .padding(12)
                                        .background(category == cat ? Color(hex: cat.color) : Color(hex: cat.color).opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        BTextField(placeholder: "Description (optional)", text: $description, icon: "text.alignleft")

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .font(.bBody()).padding(14).background(Color.bSectionBG).cornerRadius(14)

                        Toggle(isOn: $isUnexpected) {
                            Label("Unexpected expense", systemImage: "exclamationmark.triangle")
                                .font(.bBody()).foregroundColor(.bNavy)
                        }.tint(.bRed)

                        if !errorMsg.isEmpty { Text(errorMsg).font(.bCaption()).foregroundColor(.bRed) }
                        Button("Add Expense") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }.padding(20)
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }

    private func save() {
        guard let amt = Double(amount), amt > 0 else { errorMsg = "Please enter a valid amount."; return }
        dataVM.addExpense(category: category, amount: amt, description: description, date: date, isUnexpected: isUnexpected)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Expense

struct EditExpenseView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode
    let expense: BudgetExpense

    @State private var category: ExpenseCategory = .other
    @State private var amount = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var isUnexpected = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BTextField(placeholder: "Amount", text: $amount, icon: "dollarsign.circle", keyboardType: .decimalPad)
                        Picker("Category", selection: $category) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { c in Text(c.rawValue).tag(c) }
                        }.pickerStyle(MenuPickerStyle()).padding(14).background(Color.bSectionBG).cornerRadius(14)
                        BTextField(placeholder: "Description", text: $description, icon: "text.alignleft")
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .font(.bBody()).padding(14).background(Color.bSectionBG).cornerRadius(14)
                        Toggle(isOn: $isUnexpected) {
                            Label("Unexpected expense", systemImage: "exclamationmark.triangle").font(.bBody()).foregroundColor(.bNavy)
                        }.tint(.bRed)
                        Button("Save Changes") { save() }.buttonStyle(BuildoraPrimaryButtonStyle())
                    }.padding(20)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear {
                category = expense.category; amount = String(format: "%.2f", expense.amount)
                description = expense.expenseDescription; date = expense.date; isUnexpected = expense.isUnexpected
            }
        }
    }

    private func save() {
        var updated = expense
        updated.category = category; updated.amount = Double(amount) ?? expense.amount
        updated.expenseDescription = description; updated.date = date; updated.isUnexpected = isUnexpected
        dataVM.updateExpense(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
