//
//  LoginView.swift
//  TinniTrack
//

import SwiftUI
import UIKit

struct LoginView: View {
    private enum Field: Hashable {
        case email
        case password
    }

    @EnvironmentObject private var sessionStore: SessionStore

    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private let focusColor = Color(red: 0.0, green: 0.48, blue: 1.0)
    private let fieldBorderColor = Color(red: 0.82, green: 0.82, blue: 0.84)
    private let actionColor = Color(red: 0.06, green: 0.24, blue: 0.44)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color(red: 0.95, green: 0.95, blue: 0.97)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 16)

                VStack(spacing: 14) {
                    LogoView()

                    Text("Welcome to TinniTrack.")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)

                    Text("Sign in to begin your tinnitus tracking.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

                VStack(spacing: 26) {
                    VStack(spacing: 14) {
                        FloatingInputField(
                            label: "Email",
                            text: $email,
                            isSecure: false,
                            isFocused: focusedField == .email,
                            borderColor: fieldBorderColor,
                            focusedBorderColor: focusColor,
                            accessibilityIdentifier: "login_email_field",
                            clearAction: { email = "" }
                        )
                        .focused($focusedField, equals: .email)

                        FloatingInputField(
                            label: "Password",
                            text: $password,
                            isSecure: true,
                            isFocused: focusedField == .password,
                            borderColor: fieldBorderColor,
                            focusedBorderColor: focusColor,
                            accessibilityIdentifier: "login_password_field"
                        )
                        .focused($focusedField, equals: .password)

                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                Task {
                                    await sessionStore.requestPasswordReset(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
                                }
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(focusColor)
                            .disabled(sessionStore.isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityIdentifier("forgot_password_button")
                        }
                        .padding(.top, 2)
                    }

                    Button("Log In") {
                        Task {
                            await sessionStore.signIn(
                                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                password: password
                            )
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(actionColor)
                    .clipShape(Capsule())
                    .padding(.horizontal, 12)
                    .disabled(sessionStore.isLoading)
                    .accessibilityIdentifier("login_button")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 26)
                .background(Color.white.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 10)
                .padding(.horizontal, 20)

                Spacer()

                HStack(spacing: 5) {
                    Text("Don’t have an account?")
                        .foregroundStyle(Color.secondary)
                    NavigationLink("Sign Up", destination: SignUpView())
                        .foregroundStyle(focusColor)
                        .fontWeight(.semibold)
                }
                .font(.system(size: 15, weight: .regular))
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 10)

            if sessionStore.isLoading {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

private struct FloatingInputField: View {
    let label: String
    @Binding var text: String
    let isSecure: Bool
    let isFocused: Bool
    let borderColor: Color
    let focusedBorderColor: Color
    var accessibilityIdentifier: String? = nil
    var clearAction: (() -> Void)? = nil

    private var shouldFloat: Bool {
        isFocused || !text.isEmpty
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? focusedBorderColor : borderColor, lineWidth: 1.2)
                )
                .frame(height: 64)

            Text(label)
                .font(.system(size: shouldFloat ? 12 : 17, weight: shouldFloat ? .semibold : .regular))
                .foregroundStyle(shouldFloat ? Color.secondary : Color.gray)
                .padding(.horizontal, 14)
                .offset(y: shouldFloat ? -18 : 0)
                .animation(.easeInOut(duration: 0.16), value: shouldFloat)

            Group {
                if isSecure {
                    SecureField("", text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier(accessibilityIdentifier ?? "")
                } else {
                    TextField("", text: $text)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier(accessibilityIdentifier ?? "")
                }
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(.black)
            .padding(.top, shouldFloat ? 16 : 0)
            .padding(.leading, 14)
            .padding(.trailing, clearAction == nil ? 14 : 40)

            if let clearAction, !text.isEmpty, !isSecure {
                HStack {
                    Spacer()
                    Button(action: clearAction) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.gray.opacity(0.65))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

private struct LogoView: View {
    var body: some View {
        Group {
            if let image = UIImage(named: "TinniTrackLogo") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.95))
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color(red: 0.06, green: 0.24, blue: 0.44))
                }
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.85, green: 0.87, blue: 0.9), lineWidth: 1)
                )
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
