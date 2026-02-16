//
//  SessionStore.swift
//  TinniTrack
//

import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    enum Phase: Equatable {
        case loading
        case unauthenticated
        case awaitingEmailVerification
        case authenticatedNeedsOnboarding
        case authenticatedReady
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var profile: Profile?
    @Published private(set) var pendingVerificationEmail: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var shouldPresentPasswordReset = false

    private let authService: AuthServiceProtocol
    private let profileService: ProfileServiceProtocol
    private let emailVerificationPendingStore: EmailVerificationPendingStoring
    private var authStateTask: Task<Void, Never>?

    init(
        authService: AuthServiceProtocol,
        profileService: ProfileServiceProtocol,
        emailVerificationPendingStore: EmailVerificationPendingStoring? = nil
    ) {
        self.authService = authService
        self.profileService = profileService
        self.emailVerificationPendingStore = emailVerificationPendingStore ?? EmailVerificationPendingStore()
        startAuthStateListener()

        Task {
            await bootstrap()
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    func bootstrap() async {
        await refreshPhase()
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await authService.signIn(email: normalizedEmail, password: password)
            clearPendingEmailVerification()
            await refreshPhase()
        } catch {
            if authService.isEmailNotConfirmedError(error) {
                setPendingEmailVerification(normalizedEmail)
                phase = .awaitingEmailVerification
                infoMessage = "Please verify your email address before signing in."
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func signUp(email: String, password: String, firstName: String, lastName: String, dateOfBirth: Date) async {
        let metadata = SignUpMetadata(
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth
        )

        isLoading = true
        errorMessage = nil

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let result = try await authService.signUp(
                email: normalizedEmail,
                password: password,
                metadata: metadata
            )

            switch result {
            case .signedIn:
                clearPendingEmailVerification()
            case .awaitingEmailVerification:
                setPendingEmailVerification(normalizedEmail)
                infoMessage = "Check your email to verify your account."
            }

            await refreshPhase()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func completeOnboarding(firstName: String, lastName: String, dateOfBirth: Date) async {
        await runAuthAction { [self] in
            try await self.profileService.completeOnboarding(
                firstName: firstName,
                lastName: lastName,
                dateOfBirth: dateOfBirth
            )
        }
    }

    func signOut() async {
        await runAuthAction { [self] in
            try await self.authService.signOut()
        }
    }

    func requestPasswordReset(email: String) async {
        guard let redirectURL = URL(string: "tinnitrack://auth/reset") else { return }

        await runAuthAction { [self] in
            try await self.authService.requestPasswordReset(email: email, redirectURL: redirectURL)
            self.infoMessage = "If the account exists, a reset email has been sent."
        }
    }

    func handleIncomingURL(_ url: URL) async {
        do {
            let result = try await authService.handleAuthCallback(url: url)
            switch result {
            case .passwordRecovery:
                shouldPresentPasswordReset = true
            case .signedIn:
                clearPendingEmailVerification()
            case .none:
                break
            }
            await refreshPhase()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitNewPassword(_ newPassword: String) async {
        await runAuthAction { [self] in
            try await self.authService.updatePassword(newPassword: newPassword)
            self.shouldPresentPasswordReset = false
            self.infoMessage = "Password updated."
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    func dismissInfo() {
        infoMessage = nil
    }

    func resendVerificationEmail() async {
        guard let pending = emailVerificationPendingStore.load(),
              let redirectURL = URL(string: "tinnitrack://auth/confirm") else {
            return
        }

        await runAuthAction { [self] in
            try await authService.resendSignUpVerification(email: pending.email, redirectURL: redirectURL)
            emailVerificationPendingStore.updateLastResend(at: Date())
            infoMessage = "Verification email sent."
        }
    }

    func checkEmailVerificationStatus() async {
        await refreshPhase()
        if phase == .awaitingEmailVerification {
            infoMessage = "Still waiting for verification. Open the email link on this device."
        }
    }

    func useDifferentEmailForVerification() {
        clearPendingEmailVerification()
        phase = .unauthenticated
    }

    private func startAuthStateListener() {
        authStateTask?.cancel()
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await _ in authService.authStateStream() {
                await refreshPhase()
            }
        }
    }

    private func refreshPhase() async {
        phase = .loading

        do {
            guard try await authService.currentSession() != nil else {
                profile = nil
                if let pending = emailVerificationPendingStore.load() {
                    pendingVerificationEmail = pending.email
                    phase = .awaitingEmailVerification
                } else {
                    pendingVerificationEmail = nil
                    phase = .unauthenticated
                }
                return
            }

            clearPendingEmailVerification()
            let latestProfile = try await profileService.fetchMyProfile()
            profile = latestProfile

            if latestProfile?.isOnboardingComplete == true {
                phase = .authenticatedReady
            } else {
                phase = .authenticatedNeedsOnboarding
            }
        } catch {
            errorMessage = error.localizedDescription
            profile = nil
            phase = .unauthenticated
        }
    }

    private func runAuthAction(_ action: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil

        do {
            try await action()
            await refreshPhase()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func setPendingEmailVerification(_ email: String) {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        emailVerificationPendingStore.save(
            PendingEmailVerification(
                email: normalized,
                createdAt: Date(),
                lastResendAt: nil
            )
        )
        pendingVerificationEmail = normalized
    }

    private func clearPendingEmailVerification() {
        emailVerificationPendingStore.clear()
        pendingVerificationEmail = nil
    }
}
