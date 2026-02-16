import Foundation
import Testing
@testable import TinniTrack

@MainActor
struct SessionStoreTests {
    @Test
    func bootstrapMovesToUnauthenticatedWhenNoSession() async {
        let auth = MockAuthService(currentSession: nil)
        let profile = MockProfileService(profile: nil)
        let pending = MockEmailVerificationPendingStore(pending: nil)
        let store = SessionStore(authService: auth, profileService: profile, emailVerificationPendingStore: pending)

        await store.bootstrap()

        #expect(store.phase == .unauthenticated)
    }

    @Test
    func bootstrapMovesToAwaitingVerificationWhenPendingEmailExists() async {
        let auth = MockAuthService(currentSession: nil)
        let profile = MockProfileService(profile: nil)
        let pending = MockEmailVerificationPendingStore(
            pending: PendingEmailVerification(
                email: "pending@example.com",
                createdAt: Date(),
                lastResendAt: nil
            )
        )
        let store = SessionStore(authService: auth, profileService: profile, emailVerificationPendingStore: pending)

        await store.bootstrap()

        #expect(store.phase == .awaitingEmailVerification)
        #expect(store.pendingVerificationEmail == "pending@example.com")
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
        let pending = MockEmailVerificationPendingStore(pending: nil)
        let store = SessionStore(authService: auth, profileService: profile, emailVerificationPendingStore: pending)

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
        let pending = MockEmailVerificationPendingStore(
            pending: PendingEmailVerification(email: "stale@example.com", createdAt: Date(), lastResendAt: nil)
        )
        let store = SessionStore(authService: auth, profileService: profile, emailVerificationPendingStore: pending)

        await store.bootstrap()

        #expect(store.phase == .authenticatedReady)
        #expect(store.pendingVerificationEmail == nil)
    }

    @Test
    func signUpAwaitingVerificationStoresPendingAndMovesToAwaitingPhase() async {
        let auth = MockAuthService(currentSession: nil, signUpResult: .awaitingEmailVerification)
        let profile = MockProfileService(profile: nil)
        let pending = MockEmailVerificationPendingStore(pending: nil)
        let store = SessionStore(authService: auth, profileService: profile, emailVerificationPendingStore: pending)

        await store.signUp(
            email: "pending@example.com",
            password: "password123",
            firstName: "Jane",
            lastName: "Doe",
            dateOfBirth: Date()
        )

        #expect(store.phase == .awaitingEmailVerification)
        #expect(store.pendingVerificationEmail == "pending@example.com")
        #expect(pending.pending?.email == "pending@example.com")
    }

    @Test
    func signInUnconfirmedEmailMovesToAwaitingVerification() async {
        let auth = MockAuthService(
            currentSession: nil,
            signInError: MockAuthError.emailNotConfirmed
        )
        let profile = MockProfileService(profile: nil)
        let pending = MockEmailVerificationPendingStore(pending: nil)
        let store = SessionStore(authService: auth, profileService: profile, emailVerificationPendingStore: pending)

        await store.signIn(email: "pending@example.com", password: "password123")

        #expect(store.phase == .awaitingEmailVerification)
        #expect(store.pendingVerificationEmail == "pending@example.com")
        #expect(pending.pending?.email == "pending@example.com")
    }

    @Test
    func callbackSignedInClearsPendingAndMovesForward() async {
        let userID = UUID()
        let auth = MockAuthService(
            currentSession: nil,
            callbackResult: .signedIn,
            callbackSession: AuthSession(userID: userID)
        )
        let profile = MockProfileService(profile: nil)
        let pending = MockEmailVerificationPendingStore(
            pending: PendingEmailVerification(
                email: "pending@example.com",
                createdAt: Date(),
                lastResendAt: nil
            )
        )
        let store = SessionStore(authService: auth, profileService: profile, emailVerificationPendingStore: pending)

        await store.handleIncomingURL(URL(string: "tinnitrack://auth/confirm#access_token=123")!)

        #expect(store.phase == .authenticatedNeedsOnboarding)
        #expect(store.pendingVerificationEmail == nil)
        #expect(pending.pending == nil)
    }

    @Test
    func useDifferentEmailClearsPendingAndMovesToUnauthenticated() async {
        let auth = MockAuthService(currentSession: nil)
        let profile = MockProfileService(profile: nil)
        let pending = MockEmailVerificationPendingStore(
            pending: PendingEmailVerification(
                email: "pending@example.com",
                createdAt: Date(),
                lastResendAt: nil
            )
        )
        let store = SessionStore(authService: auth, profileService: profile, emailVerificationPendingStore: pending)

        await store.bootstrap()
        store.useDifferentEmailForVerification()

        #expect(store.phase == .unauthenticated)
        #expect(store.pendingVerificationEmail == nil)
        #expect(pending.pending == nil)
    }
}

private final class MockAuthService: AuthServiceProtocol {
    private var storedSession: AuthSession?
    private let signUpResult: SignUpResult
    private let signInError: Error?
    private let callbackResult: AuthCallbackResult
    private let callbackSession: AuthSession?

    init(
        currentSession: AuthSession?,
        signUpResult: SignUpResult = .signedIn,
        signInError: Error? = nil,
        callbackResult: AuthCallbackResult = .none,
        callbackSession: AuthSession? = nil
    ) {
        self.storedSession = currentSession
        self.signUpResult = signUpResult
        self.signInError = signInError
        self.callbackResult = callbackResult
        self.callbackSession = callbackSession
    }

    func signUp(email: String, password: String, metadata: SignUpMetadata) async throws -> SignUpResult {
        signUpResult
    }

    func signIn(email: String, password: String) async throws {
        if let signInError {
            throw signInError
        }
    }

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

    func resendSignUpVerification(email: String, redirectURL: URL) async throws {}
    func isEmailNotConfirmedError(_ error: Error) -> Bool {
        guard let mockError = error as? MockAuthError else { return false }
        return mockError == .emailNotConfirmed
    }
    func requestPasswordReset(email: String, redirectURL: URL) async throws {}
    func handleAuthCallback(url: URL) async throws -> AuthCallbackResult {
        if callbackResult == .signedIn {
            storedSession = callbackSession
        }
        return callbackResult
    }
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

private enum MockAuthError: LocalizedError {
    case emailNotConfirmed

    var errorDescription: String? {
        switch self {
        case .emailNotConfirmed:
            return "Email not confirmed"
        }
    }
}

private final class MockEmailVerificationPendingStore: EmailVerificationPendingStoring {
    var pending: PendingEmailVerification?

    init(pending: PendingEmailVerification?) {
        self.pending = pending
    }

    func load() -> PendingEmailVerification? {
        pending
    }

    func save(_ pending: PendingEmailVerification) {
        self.pending = pending
    }

    func updateLastResend(at date: Date) {
        guard var pending else { return }
        pending.lastResendAt = date
        self.pending = pending
    }

    func clear() {
        pending = nil
    }
}
