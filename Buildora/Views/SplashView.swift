import SwiftUI
import Combine
import Network

struct SplashView: View {
    
    @State private var showBlock1 = false
    @State private var showBlock2 = false
    @State private var showBlock3 = false
    @State private var showBlock4 = false
    @State private var showBlock5 = false
    @State private var showLogo = false
    @State private var showTagline = false
    @State private var circleScale: CGFloat = 0.1
    @StateObject private var container = BuildoraContainer()
    @State private var bgOpacity: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                    .opacity(bgOpacity)
                
                GeometryReader { geometry in
                    Image("loading_bg")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .opacity(0.8)
                        .blur(radius: 2)
                }
                .ignoresSafeArea()

                // Decorative circles
                Circle()
                    .fill(Color.bYellow.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -200)
                    .scaleEffect(circleScale)

                Circle()
                    .fill(Color.bOrange.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: 120, y: 250)
                    .scaleEffect(circleScale)

                Circle()
                    .fill(Color.bTeal.opacity(0.12))
                    .frame(width: 150, height: 150)
                    .offset(x: -80, y: 280)
                    .scaleEffect(circleScale)

                VStack(spacing: 32) {
                    // Tower of blocks
                    VStack(spacing: 3) {
                        // Block 5 (top)
                        buildingBlock(color: .bRed, width: 50, delay: 0.1, show: $showBlock5)
                        // Block 4
                        buildingBlock(color: .bOrange, width: 60, delay: 0.3, show: $showBlock4)
                        // Block 3
                        buildingBlock(color: .bYellow, width: 70, delay: 0.5, show: $showBlock3)
                        // Block 2
                        buildingBlock(color: .bTeal, width: 80, delay: 0.7, show: $showBlock2)
                        // Block 1 (bottom)
                        buildingBlock(color: .bBlue, width: 90, delay: 0.9, show: $showBlock1)
                    }

                    // Logo text
                    VStack(spacing: 8) {
                        Text("Buildora")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(showLogo ? 1 : 0)
                            .scaleEffect(showLogo ? 1 : 0.7)

                        Text("Plan repairs step by step")
                            .font(.bSubhead())
                            .foregroundColor(.white.opacity(0.6))
                            .opacity(showTagline ? 1 : 0)
                            .offset(y: showTagline ? 0 : 10)
                        
                        ProgressView().tint(.white)
                            .opacity(showTagline ? 1 : 0)
                            .offset(y: showTagline ? 0 : 10)
                    }
                    
                    NavigationLink(
                        destination: BuildoraWebView().navigationBarHidden(true),
                        isActive: $container.navigateToWeb
                    ) { EmptyView() }
                    
                    NavigationLink(
                        destination: MainView().navigationBarBackButtonHidden(true),
                        isActive: $container.navigateToMain
                    ) { EmptyView() }
                }
            }
            .onAppear {
                startAnimation()
                container.application.initialize()
            }
            .fullScreenCover(isPresented: $container.showPermissionPrompt) {
                BuildoraNotificationView(useCase: container.application)
            }
            .fullScreenCover(isPresented: $container.showOfflineView) {
                UnavailableView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func buildingBlock(color: Color, width: CGFloat, delay: Double, show: Binding<Bool>) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(color)
            .frame(width: width, height: 26)
            .shadow(color: color.opacity(0.4), radius: 6, y: 4)
            .offset(y: show.wrappedValue ? 0 : -30)
            .opacity(show.wrappedValue ? 1 : 0)
    }

    private func startAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            bgOpacity = 1
            circleScale = 1
        }

        let blocks: [Binding<Bool>] = [$showBlock1, $showBlock2, $showBlock3, $showBlock4, $showBlock5]
        for (i, block) in blocks.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + Double(i) * 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    block.wrappedValue = true
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showLogo = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showTagline = true
            }
        }
    }
}

@MainActor
final class BuildoraContainer: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    let application: BuildoraApplication
    let eventPublisher: UIEventPublisher
    let networkMonitor: NetworkMonitorAdapter
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let storage = DiskStorageAdapter()
        let validation = FirebaseValidationAdapter()
        let network = HTTPNetworkAdapter()
        let notification = SystemNotificationAdapter()
        let events = UIEventPublisher()
        
        self.eventPublisher = events
        
        self.application = BuildoraApplication(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification,
            events: events
        )
        
        self.networkMonitor = NetworkMonitorAdapter(useCase: application)
        
        events.$showPermissionPrompt
            .sink { [weak self] value in
                self?.showPermissionPrompt = value
            }
            .store(in: &cancellables)
        
        events.$showOfflineView
            .sink { [weak self] value in
                self?.showOfflineView = value
            }
            .store(in: &cancellables)
        
        events.$navigateToMain
            .sink { [weak self] value in
                self?.navigateToMain = value
            }
            .store(in: &cancellables)
        
        events.$navigateToWeb
            .sink { [weak self] value in
                self?.navigateToWeb = value
            }
            .store(in: &cancellables)
        
        setupStreams()
        networkMonitor.start()
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { [weak self] data in
                self?.application.handleTracking(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { [weak self] data in
                self?.application.handleNavigation(data)
            }
            .store(in: &cancellables)
    }
}

struct BuildoraNotificationView: View {
    let useCase: ApplicationUseCase
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("push_notifications_background")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                useCase.requestPermission()
            } label: {
                Image("push_notifications_first_btn")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                useCase.deferPermission()
            } label: {
                Image("push_notifications_second_btn")
                    .resizable()
                    .frame(width: 280, height: 40)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                Image("wifi_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.8)
                    .blur(radius: 2)
                
                Image("wifi_alert")
                    .resizable()
                    .frame(width: 250, height: 180)
            }
        }
        .ignoresSafeArea()
    }
}


struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
