import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = AuthViewModel()
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            Color.bBG.ignoresSafeArea()

            // Background decorations
            Circle()
                .fill(LinearGradient.bYellowOrange)
                .frame(width: 300, height: 300)
                .offset(x: 120, y: -200)
                .opacity(0.2)

            Circle()
                .fill(Color.bBlue.opacity(0.15))
                .frame(width: 200, height: 200)
                .offset(x: -100, y: 300)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        BlockTower(blockCount: 4)
                            .padding(.top, 60)

                        Text("Buildora")
                            .font(.bLargeTitle())
                            .foregroundColor(.bNavy)

                        Text(vm.isRegistering ? "Create your account" : "Welcome back")
                            .font(.bBody())
                            .foregroundColor(.bNavy.opacity(0.6))
                    }

                    // Form
                    VStack(spacing: 16) {
                        if vm.isRegistering {
                            BTextField(placeholder: "Your name", text: $vm.registerName, icon: "person")
                            BTextField(placeholder: "Email address", text: $vm.registerEmail, icon: "envelope", keyboardType: .emailAddress)
                            BTextField(placeholder: "Password (min 6 chars)", text: $vm.registerPassword, icon: "lock", isSecure: true)
                            BTextField(placeholder: "Confirm password", text: $vm.registerConfirmPassword, icon: "lock.shield", isSecure: true)
                        } else {
                            BTextField(placeholder: "Email address", text: $vm.loginEmail, icon: "envelope", keyboardType: .emailAddress)
                            BTextField(placeholder: "Password", text: $vm.loginPassword, icon: "lock", isSecure: true)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Error
                    if vm.showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(vm.errorMessage)
                                .font(.bCaption())
                        }
                        .foregroundColor(.bRed)
                        .padding(12)
                        .background(Color.bRed.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }

                    // Action Button
                    Button(action: {
                        if vm.isRegistering {
                            vm.register(appState: appState)
                        } else {
                            vm.login(appState: appState)
                        }
                    }) {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text(vm.isRegistering ? "Create Account" : "Sign In")
                        }
                    }
                    .buttonStyle(BuildoraPrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .disabled(vm.isLoading)

                    // Toggle mode
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.isRegistering.toggle()
                            vm.clearFields()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(vm.isRegistering ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.bNavy.opacity(0.6))
                            Text(vm.isRegistering ? "Sign In" : "Register")
                                .foregroundColor(.bOrange)
                                .fontWeight(.semibold)
                        }
                        .font(.bBody())
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
