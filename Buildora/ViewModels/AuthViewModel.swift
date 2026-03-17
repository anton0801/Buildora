import SwiftUI
import Combine

final class AuthViewModel: ObservableObject {
    @Published var loginEmail: String = ""
    @Published var loginPassword: String = ""
    @Published var registerName: String = ""
    @Published var registerEmail: String = ""
    @Published var registerPassword: String = ""
    @Published var registerConfirmPassword: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var isRegistering: Bool = false

    private let store = DataStore.shared

    // MARK: - Login

    func login(appState: AppState) {
        guard validate(mode: .login) else { return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = self.store.loginUser(email: self.loginEmail, password: self.loginPassword)
            self.isLoading = false
            switch result {
            case .success(let user):
                appState.login(user: user)
            case .failure(let error):
                self.showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Register

    func register(appState: AppState) {
        guard validate(mode: .register) else { return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = self.store.registerUser(name: self.registerName, email: self.registerEmail, password: self.registerPassword)
            self.isLoading = false
            switch result {
            case .success(let user):
                appState.login(user: user)
            case .failure(let error):
                self.showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Validation

    enum AuthMode { case login, register }

    private func validate(mode: AuthMode) -> Bool {
        switch mode {
        case .login:
            guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
                showError("Please fill in all fields.")
                return false
            }
        case .register:
            guard !registerName.trimmingCharacters(in: .whitespaces).isEmpty else {
                showError("Please enter your name.")
                return false
            }
            guard isValidEmail(registerEmail) else {
                showError(AuthError.invalidEmail.localizedDescription ?? "Invalid email")
                return false
            }
            guard registerPassword.count >= 6 else {
                showError(AuthError.weakPassword.localizedDescription ?? "Weak password")
                return false
            }
            guard registerPassword == registerConfirmPassword else {
                showError("Passwords don't match.")
                return false
            }
        }
        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    func clearFields() {
        loginEmail = ""
        loginPassword = ""
        registerName = ""
        registerEmail = ""
        registerPassword = ""
        registerConfirmPassword = ""
        errorMessage = ""
        showError = false
    }
}
