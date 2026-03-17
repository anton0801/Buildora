import SwiftUI

struct MoreView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var showSettings = false

    private let items: [(String, String, Color, MoreDestination)] = [
        ("Materials",     "cube.box.fill",           .bRed,    .materials),
        ("Measurements",  "ruler.fill",               .bBlue,   .measurements),
        ("Photos",        "photo.on.rectangle.fill",  .bGreen,  .photos),
        ("Contacts",      "person.crop.circle.fill",  .bOrange, .contacts),
        ("Rooms",         "rectangle.3.group.fill",   .bTeal,   .rooms),
        ("Shopping",      "cart.fill",                .bTeal,   .shopping),
        ("Calendar",      "calendar",                 .bBlue,   .calendar),
        ("Insights",      "chart.bar.fill",           .bYellow, .insights),
    ]

    enum MoreDestination: Hashable {
        case materials, measurements, photos, contacts, rooms, shopping, calendar, insights
    }

    @State private var destination: MoreDestination? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color.bBG.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Project context
                        if let project = appState.selectedProject {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill").foregroundColor(.bOrange)
                                Text("Active: \(project.name)")
                                    .font(.bBody()).foregroundColor(.bNavy)
                                Spacer()
                                BTag(text: project.status.rawValue, color: Color(hex: project.status.color), small: true)
                            }
                            .padding(14)
                            .background(Color.bYellow.opacity(0.08))
                            .cornerRadius(14)
                            .padding(.horizontal, 20)
                        }

                        // Grid of options
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(items, id: \.0) { item in
                                MoreGridCell(label: item.0, icon: item.1, color: item.2) {
                                    destination = item.3
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Settings button
                        Button(action: { showSettings = true }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.bNavy.opacity(0.08))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.bNavy)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Settings").font(.bSubhead()).foregroundColor(.bNavy)
                                    Text("Theme, currency, account")
                                        .font(.bCaption()).foregroundColor(.bNavy.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.bNavy.opacity(0.3))
                            }
                            .padding(16).bCardStyle()
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }

                // NavigationLinks (hidden)
                NavigationLink(destination: destinationView, tag: destination ?? .materials, selection: $destination) {
                    EmptyView()
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(appState)
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch destination {
        case .materials:    MaterialsView().environmentObject(dataVM).environmentObject(appState)
        case .measurements: MeasurementsView().environmentObject(dataVM).environmentObject(appState)
        case .photos:       ProgressPhotosView().environmentObject(dataVM).environmentObject(appState)
        case .contacts:     ContactsView().environmentObject(dataVM).environmentObject(appState)
        case .rooms:        RoomsView().environmentObject(dataVM).environmentObject(appState)
        case .shopping:     ShoppingView().environmentObject(dataVM).environmentObject(appState)
        case .calendar:     CalendarView().environmentObject(dataVM).environmentObject(appState)
        case .insights:     InsightsView().environmentObject(dataVM).environmentObject(appState)
        case nil:           EmptyView()
        }
    }
}

// MARK: - More Grid Cell

struct MoreGridCell: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(color.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.bBody())
                    .foregroundColor(.bNavy)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(20)
            .bShadow(0.08)
            .scaleEffect(pressed ? 0.94 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
