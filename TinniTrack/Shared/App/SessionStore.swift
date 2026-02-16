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
        case authenticatedNeedsOnboarding
        case authenticatedReady
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var shouldPresentPasswordReset = false

    private let authService: AuthServiceProtocol
    private let profileService: ProfileServiceProtocol
    private var authStateTask: Task<Void, Never>?

    init(
        authService: AuthServiceProtocol,
        profileService: ProfileServiceProtocol
    ) {
        self.authService = authService
        self.profileService = profileService
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
        await runAuthAction { [self] in
            try await self.authService.signIn(email: email, password: password)
        }
    }

    func signUp(email: String, password: String, firstName: String, lastName: String, dateOfBirth: Date) async {
        let metadata = SignUpMetadata(
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth
        )

        await runAuthAction { [self] in
            try await self.authService.signUp(email: email, password: password, metadata: metadata)

            // If session is not created automatically for any reason, fall back to explicit sign-in.
            if try await self.authService.currentSession() == nil {
                try await self.authService.signIn(email: email, password: password)
            }
        }
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
            case .signedIn, .none:
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
                phase = .unauthenticated
                return
            }

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
}
