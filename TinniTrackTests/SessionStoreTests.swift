import Foundation
import Testing
@testable import TinniTrack

@MainActor
struct SessionStoreTests {
    @Test
    func bootstrapMovesToUnauthenticatedWhenNoSession() async {
        let auth = MockAuthService(currentSession: nil)
        let profile = MockProfileService(profile: nil)
        let store = SessionStore(authService: auth, profileService: profile)

        await store.bootstrap()

        #expect(store.phase == .unauthenticated)
    }

    @Test
    func bootstrapMovesToNeedsOnboardingWhenSessionExistsWithoutCompletion() async {
        let userID = UUID()
        let auth = MockAuthService(currentSession: AuthSession(userID: userID))
        let profile = MockProfileService(
            profile: Profile(
                id: userID,
                participantID: nil,
                firstName: "Jane",
                lastName: "Doe",
                dateOfBirth: Date(),
                timezone: nil,
                createdAt: nil,
                onboardingCompletedAt: nil
            )
        )
        let store = SessionStore(authService: auth, profileService: profile)

        await store.bootstrap()

        #expect(store.phase == .authenticatedNeedsOnboarding)
    }

    @Test
    func bootstrapMovesToReadyWhenProfileCompleted() async {
        let userID = UUID()
        let auth = MockAuthService(currentSession: AuthSession(userID: userID))
        let profile = MockProfileService(
            profile: Profile(
                id: userID,
                participantID: nil,
                firstName: "Jane",
                lastName: "Doe",
                dateOfBirth: Date(),
                timezone: nil,
                createdAt: nil,
                onboardingCompletedAt: Date()
            )
        )
        let store = SessionStore(authService: auth, profileService: profile)

        await store.bootstrap()

        #expect(store.phase == .authenticatedReady)
    }
}

private final class MockAuthService: AuthServiceProtocol {
    private var storedSession: AuthSession?

    init(currentSession: AuthSession?) {
        self.storedSession = currentSession
    }

    func signUp(email: String, password: String, metadata: SignUpMetadata) async throws {}
    func signIn(email: String, password: String) async throws {}
    func signOut() async throws {
        storedSession = nil
    }

    func currentSession() async throws -> AuthSession? {
        storedSession
    }

    func authStateStream() -> AsyncStream<AuthStateChange> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func requestPasswordReset(email: String, redirectURL: URL) async throws {}
    func handleAuthCallback(url: URL) async throws -> AuthCallbackResult { .none }
    func updatePassword(newPassword: String) async throws {}
}

private final class MockProfileService: ProfileServiceProtocol {
    private(set) var profile: Profile?

    init(profile: Profile?) {
        self.profile = profile
    }

    func fetchMyProfile() async throws -> Profile? {
        profile
    }

    func completeOnboarding(firstName: String, lastName: String, dateOfBirth: Date) async throws {
        profile = Profile(
            id: profile?.id ?? UUID(),
            participantID: profile?.participantID,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            timezone: profile?.timezone,
            createdAt: profile?.createdAt,
            onboardingCompletedAt: Date()
        )
    }
}
