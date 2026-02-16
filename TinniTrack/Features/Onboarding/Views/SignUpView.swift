//
//  SignUpView.swift
//  TinniTrack
//

import SwiftUI
import UIKit

struct SignUpView: View {
    private enum Field: Hashable {
        case firstName
        case lastName
        case email
        case password
    }

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @FocusState private var focusedField: Field?

    private let focusColor = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let fieldBorderColor = Color(red: 0.82, green: 0.82, blue: 0.84) // #D1D1D6
    private let actionColor = Color(red: 0.06, green: 0.24, blue: 0.44)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color(red: 0.95, green: 0.95, blue: 0.97)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Create your account")
                            .font(.system(size: 31, weight: .bold))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)

                        Text("Set up your profile to start tinnitus tracking.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 14) {
                        FloatingInputField(
                            label: "First Name",
                            text: $firstName,
                            isSecure: false,
                            isFocused: focusedField == .firstName,
                            borderColor: fieldBorderColor,
                            focusedBorderColor: focusColor
                        )
                        .focused($focusedField, equals: .firstName)

                        FloatingInputField(
                            label: "Last Name",
                            text: $lastName,
                            isSecure: false,
                            isFocused: focusedField == .lastName,
                            borderColor: fieldBorderColor,
                            focusedBorderColor: focusColor
                        )
                        .focused($focusedField, equals: .lastName)

                        FloatingInputField(
                            label: "Email",
                            text: $email,
                            isSecure: false,
                            isFocused: focusedField == .email,
                            borderColor: fieldBorderColor,
                            focusedBorderColor: focusColor,
                            keyboardType: .emailAddress,
                            clearAction: { email = "" }
                        )
                        .focused($focusedField, equals: .email)

                        FloatingInputField(
                            label: "Password",
                            text: $password,
                            isSecure: true,
                            isFocused: focusedField == .password,
                            borderColor: fieldBorderColor,
                            focusedBorderColor: focusColor
                        )
                        .focused($focusedField, equals: .password)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                            DatePicker(
                                "",
                                selection: $dateOfBirth,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(focusColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(fieldBorderColor, lineWidth: 1.2)
                        )

                    }

                    Button("Create Account") {}
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(actionColor)
                        .clipShape(Capsule())
                        .padding(.top, 8)
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
                .padding(.vertical, 18)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FloatingInputField: View {
    let label: String
    @Binding var text: String
    let isSecure: Bool
    let isFocused: Bool
    let borderColor: Color
    let focusedBorderColor: Color
    var keyboardType: UIKeyboardType = .default
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
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
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

#Preview {
    NavigationStack {
        SignUpView()
    }
}
