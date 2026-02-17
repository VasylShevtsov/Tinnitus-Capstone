//
//  SupabaseAuthService.swift
//  TinniTrack
//

import Foundation
import Supabase

final class SupabaseAuthService: AuthServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = supabase) {
        self.client = client
    }

    func signUp(email: String, password: String, metadata: SignUpMetadata) async throws -> SignUpResult {
        var data: [String: AnyJSON] = [:]
        if let firstName = metadata.firstName?.trimmingCharacters(in: .whitespacesAndNewlines), !firstName.isEmpty {
            data["first_name"] = .string(firstName)
        }
        if let lastName = metadata.lastName?.trimmingCharacters(in: .whitespacesAndNewlines), !lastName.isEmpty {
            data["last_name"] = .string(lastName)
        }
        if let dateOfBirth = metadata.dateOfBirth {
            data["date_of_birth"] = .string(Self.dateOnlyFormatter.string(from: dateOfBirth))
        }

        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: data,
            redirectTo: Self.confirmEmailRedirectURL
        )

        return response.session == nil ? .awaitingEmailVerification : .signedIn
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func currentSession() async throws -> AuthSession? {
        do {
            let session = try await client.auth.session
            return AuthSession(userID: session.user.id)
        } catch {
            return nil
        }
    }

    func authStateStream() -> AsyncStream<AuthStateChange> {
        AsyncStream { continuation in
            let task = Task {
                for await (event, session) in client.auth.authStateChanges {
                    continuation.yield(
                        AuthStateChange(
                            event: Self.mapEvent(description: String(describing: event)),
                            session: session.map { AuthSession(userID: $0.user.id) }
                        )
                    )
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func resendSignUpVerification(email: String, redirectURL: URL) async throws {
        try await client.auth.resend(
            email: email,
            type: .signup,
            emailRedirectTo: redirectURL
        )
    }

    func isEmailNotConfirmedError(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("email not confirmed")
            || message.contains("email_not_confirmed")
            || message.contains("email not verified")
    }

    func requestPasswordReset(email: String, redirectURL: URL) async throws {
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: redirectURL
        )
    }

    func handleAuthCallback(url: URL) async throws -> AuthCallbackResult {
        let params = Self.authParams(from: url)

        if let errorDescription = params["error_description"], !errorDescription.isEmpty {
            throw NSError(
                domain: "AuthCallback",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: errorDescription.replacingOccurrences(of: "+", with: " ")]
            )
        }

        if let accessToken = params["access_token"],
           let refreshToken = params["refresh_token"],
           !accessToken.isEmpty,
           !refreshToken.isEmpty {
            _ = try await client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
        } else {
            _ = try await client.auth.session(from: url)
        }

        if Self.isRecoveryURL(url) {
            return .passwordRecovery
        }
        return .signedIn
    }

    func updatePassword(newPassword: String) async throws {
        try await client.auth.update(
            user: UserAttributes(password: newPassword)
        )
    }

    private static func mapEvent(description: String) -> AuthEvent {
        switch description.lowercased() {
        case "initialsession":
            return .initialSession
        case "signedin":
            return .signedIn
        case "signedout":
            return .signedOut
        case "tokenrefreshed":
            return .tokenRefreshed
        case "userupdated":
            return .userUpdated
        case "passwordrecovery":
            return .passwordRecovery
        default:
            return .unknown
        }
    }

    private static func isRecoveryURL(_ url: URL) -> Bool {
        authItems(from: url).contains { item in
            item.name == "type" && item.value?.lowercased() == "recovery"
        }
    }

    private static func authParams(from url: URL) -> [String: String] {
        var params: [String: String] = [:]
        for item in authItems(from: url) {
            params[item.name] = item.value
        }
        return params
    }

    private static func authItems(from url: URL) -> [URLQueryItem] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return []
        }
        return (components.queryItems ?? []) + Self.queryItems(fromFragment: components.fragment)
    }

    private static func queryItems(fromFragment fragment: String?) -> [URLQueryItem] {
        guard let fragment, !fragment.isEmpty else { return [] }
        return fragment
            .split(separator: "&")
            .map(String.init)
            .compactMap {
                let pair = $0.split(separator: "=", maxSplits: 1).map(String.init)
                guard let name = pair.first else { return nil }
                let value = pair.count > 1 ? pair[1] : nil
                return URLQueryItem(name: name, value: value)
            }
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let confirmEmailRedirectURL = URL(string: "tinnitrack://auth/confirm")!
}
