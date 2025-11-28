//
//  AuthenticationManager.swift
//  Still App
//
//  Created by Akinyemi Bajulaiye on 9/20/25.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

// MARK: - User Model
struct StillUser: Codable {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: String?
    let isAnonymous: Bool
    
    init(uid: String, email: String? = nil, displayName: String? = nil, photoURL: String? = nil, isAnonymous: Bool = false) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isAnonymous = isAnonymous
    }
    
    init(from firebaseUser: User) {
        self.uid = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL?.absoluteString
        self.isAnonymous = firebaseUser.isAnonymous
    }
}

// MARK: - Authentication State
enum AuthenticationState {
    case unknown
    case authenticated(StillUser)
    case unauthenticated
}

// MARK: - Authentication Error
enum AuthenticationError: LocalizedError {
    case signInFailed(String)
    case signOutFailed(String)
    case userNotFound
    case invalidCredential
    case networkError
    case noRootViewController
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .userNotFound:
            return "User not found"
        case .invalidCredential:
            return "Invalid credentials"
        case .networkError:
            return "Network error. Please check your connection."
        case .noRootViewController:
            return "Unable to present sign in screen"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var authState: AuthenticationState = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // For Sign in with Apple
    private var currentNonce: String?
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    var currentUser: StillUser? {
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }
    
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
    
    private init() {
        // Listen for auth state changes
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Setup Auth State Listener
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    let stillUser = StillUser(from: user)
                    self?.authState = .authenticated(stillUser)
                    
                    // Save to UserDefaults as backup
                    if let encoded = try? JSONEncoder().encode(stillUser) {
                        UserDefaults.standard.set(encoded, forKey: "currentUser")
                    }
                } else {
                    // Check for guest user in UserDefaults
                    if let userData = UserDefaults.standard.data(forKey: "currentUser"),
                       let user = try? JSONDecoder().decode(StillUser.self, from: userData),
                       user.isAnonymous {
                        self?.authState = .authenticated(user)
                    } else {
                        self?.authState = .unauthenticated
                    }
                }
            }
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthenticationError.signInFailed("Firebase not configured properly")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthenticationError.noRootViewController
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthenticationError.signInFailed("Failed to get ID token")
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let stillUser = StillUser(from: authResult.user)
            authState = .authenticated(stillUser)
            
        } catch let error as GIDSignInError {
            if error.code == .canceled {
                // User cancelled - not an error
                return
            }
            throw AuthenticationError.signInFailed(error.localizedDescription)
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }
    
    // MARK: - Sign in with Apple
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let nonce = currentNonce,
               let appleIDToken = appleIDCredential.identityToken,
               let idTokenString = String(data: appleIDToken, encoding: .utf8) {
                
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )
                
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)
                    let stillUser = StillUser(from: authResult.user)
                    authState = .authenticated(stillUser)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            
        case .failure(let error):
            // Check if user cancelled
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            UserDefaults.standard.removeObject(forKey: "currentUser")
            authState = .unauthenticated
        } catch {
            throw AuthenticationError.signOutFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Continue as Guest
    func continueAsGuest() {
        let guestUser = StillUser(
            uid: UUID().uuidString,
            email: nil,
            displayName: "Guest",
            photoURL: nil,
            isAnonymous: true
        )
        
        if let encoded = try? JSONEncoder().encode(guestUser) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        
        authState = .authenticated(guestUser)
    }
    
    // MARK: - Apple Sign In Helpers
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
}

// MARK: - Sign in with Apple Button
struct SignInWithAppleButton: View {
    @ObservedObject var authManager = AuthenticationManager.shared
    var onComplete: () -> Void = {}
    
    var body: some View {
        SignInWithAppleButtonViewRepresentable(
            onRequest: { request in
                let nonce = authManager.generateNonce()
                request.requestedScopes = [.fullName, .email]
                request.nonce = authManager.sha256(nonce)
            },
            onCompletion: { result in
                Task {
                    await authManager.handleSignInWithApple(result)
                    if authManager.isAuthenticated {
                        onComplete()
                    }
                }
            }
        )
        .frame(height: 56)
        .cornerRadius(16)
    }
}

struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTapButton), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: SignInWithAppleButtonViewRepresentable
        
        init(_ parent: SignInWithAppleButtonViewRepresentable) {
            self.parent = parent
        }
        
        @objc func didTapButton() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            parent.onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                return UIWindow()
            }
            return window
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            parent.onCompletion(.failure(error))
        }
    }
}
