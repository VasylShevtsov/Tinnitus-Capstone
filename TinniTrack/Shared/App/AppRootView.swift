//
//  AppRootView.swift
//  TinniTrack
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        NavigationStack {
            switch sessionStore.phase {
            case .loading:
                ProgressView("Loading…")
            case .unauthenticated:
                LoginView()
            case .awaitingEmailVerification:
                EmailVerificationPendingView()
            case .authenticatedNeedsOnboarding:
                CompleteOnboardingView()
            case .authenticatedReady:
                HomeView()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { sessionStore.errorMessage != nil },
            set: { _ in sessionStore.dismissError() }
        )) {
            Button("OK", role: .cancel) { sessionStore.dismissError() }
        } message: {
            Text(sessionStore.errorMessage ?? "")
        }
        .alert("Info", isPresented: Binding(
            get: { sessionStore.infoMessage != nil },
            set: { _ in sessionStore.dismissInfo() }
        )) {
            Button("OK", role: .cancel) { sessionStore.dismissInfo() }
        } message: {
            Text(sessionStore.infoMessage ?? "")
        }
        .fullScreenCover(isPresented: $sessionStore.shouldPresentPasswordReset) {
            ResetPasswordView()
                .environmentObject(sessionStore)
        }
    }
}

#Preview {
    AppRootView()
}
