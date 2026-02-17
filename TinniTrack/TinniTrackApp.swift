//
//  TinniTrackApp.swift
//  TinniTrack
//

import SwiftUI
import Foundation

@main
struct TinniTrackApp: App {
    @StateObject private var sessionStore: SessionStore

    init() {
        _sessionStore = StateObject(wrappedValue: Self.makeSessionStore())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(sessionStore)
                .onOpenURL { url in
                    Task {
                        await sessionStore.handleIncomingURL(url)
                    }
                }
        }
    }

    private static func makeSessionStore() -> SessionStore {
        let pendingStore = EmailVerificationPendingStore()

        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            let env = ProcessInfo.processInfo.environment
            if env["UITEST_CLEAR_PENDING_VERIFICATION"] == "1" {
                pendingStore.clear()
            }
            if env["UITEST_CLEAR_SIGNUP_DRAFT"] == "1" {
                let draftStore = SignupDraftStore()
                draftStore.clear()
            }
            if let pendingEmail = env["UITEST_PENDING_VERIFICATION_EMAIL"]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !pendingEmail.isEmpty {
                pendingStore.save(
                    PendingEmailVerification(
                        email: pendingEmail,
                        createdAt: Date(),
                        lastResendAt: nil
                    )
                )
            }

            return SessionStore(
                authService: NoopAuthService(),
                profileService: NoopProfileService(),
                emailVerificationPendingStore: pendingStore
            )
        }

        return SessionStore(
            authService: SupabaseAuthService(),
            profileService: SupabaseProfileService(),
            emailVerificationPendingStore: pendingStore
        )
    }
}

private final class NoopAuthService: AuthServiceProtocol {
    private var currentSessionCallCount = 0
    private let verifyAfterSessionChecks: Int?

    init(processInfo: ProcessInfo = .processInfo) {
        if let raw = processInfo.environment["UITEST_NOOP_VERIFY_AFTER_SESSION_CHECKS"] {
            verifyAfterSessionChecks = Int(raw)
        } else {
            verifyAfterSessionChecks = nil
        }
    }

    func signUp(email: String, password: String, metadata: SignUpMetadata) async throws -> SignUpResult {
        .awaitingEmailVerification
    }
    func signIn(email: String, password: String) async throws {}
    func signOut() async throws {}
    func currentSession() async throws -> AuthSession? {
        currentSessionCallCount += 1
        guard let verifyAfterSessionChecks else { return nil }
        guard currentSessionCallCount >= verifyAfterSessionChecks else { return nil }
        return AuthSession(userID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    }
    func authStateStream() -> AsyncStream<AuthStateChange> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    func resendSignUpVerification(email: String, redirectURL: URL) async throws {}
    func isEmailNotConfirmedError(_ error: Error) -> Bool { false }
    func requestPasswordReset(email: String, redirectURL: URL) async throws {}
    func handleAuthCallback(url: URL) async throws -> AuthCallbackResult { .none }
    func updatePassword(newPassword: String) async throws {}
}

private final class NoopProfileService: ProfileServiceProtocol {
    func fetchMyProfile() async throws -> Profile? { nil }
    func completeOnboarding(firstName: String, lastName: String, dateOfBirth: Date) async throws {}
}
