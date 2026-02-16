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
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return SessionStore(
                authService: NoopAuthService(),
                profileService: NoopProfileService()
            )
        }

        return SessionStore(
            authService: SupabaseAuthService(),
            profileService: SupabaseProfileService()
        )
    }
}

private final class NoopAuthService: AuthServiceProtocol {
    func signUp(email: String, password: String, metadata: SignUpMetadata) async throws {}
    func signIn(email: String, password: String) async throws {}
    func signOut() async throws {}
    func currentSession() async throws -> AuthSession? { nil }
    func authStateStream() -> AsyncStream<AuthStateChange> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    func requestPasswordReset(email: String, redirectURL: URL) async throws {}
    func handleAuthCallback(url: URL) async throws -> AuthCallbackResult { .none }
    func updatePassword(newPassword: String) async throws {}
}

private final class NoopProfileService: ProfileServiceProtocol {
    func fetchMyProfile() async throws -> Profile? { nil }
    func completeOnboarding(firstName: String, lastName: String, dateOfBirth: Date) async throws {}
}
