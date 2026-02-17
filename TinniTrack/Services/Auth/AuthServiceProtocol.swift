//
//  AuthServiceProtocol.swift
//  TinniTrack
//

import Foundation

struct AuthSession: Equatable {
    let userID: UUID
}

enum SignUpResult: Equatable {
    case signedIn
    case awaitingEmailVerification
}

enum AuthEvent: Equatable {
    case initialSession
    case signedIn
    case signedOut
    case tokenRefreshed
    case userUpdated
    case passwordRecovery
    case unknown
}

struct AuthStateChange: Equatable {
    let event: AuthEvent
    let session: AuthSession?
}

struct SignUpMetadata: Encodable, Equatable {
    let firstName: String?
    let lastName: String?
    let dateOfBirth: Date?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
    }
}

enum AuthCallbackResult: Equatable {
    case none
    case signedIn
    case passwordRecovery
}

protocol AuthServiceProtocol {
    func signUp(email: String, password: String, metadata: SignUpMetadata) async throws -> SignUpResult
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func currentSession() async throws -> AuthSession?
    func authStateStream() -> AsyncStream<AuthStateChange>
    func resendSignUpVerification(email: String, redirectURL: URL) async throws
    func isEmailNotConfirmedError(_ error: Error) -> Bool
    func requestPasswordReset(email: String, redirectURL: URL) async throws
    func handleAuthCallback(url: URL) async throws -> AuthCallbackResult
    func updatePassword(newPassword: String) async throws
}
