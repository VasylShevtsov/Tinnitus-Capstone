//
//  SignUpView.swift
//  Tinnitus Capstone
//
//  Created by Anika Patel on 11/10/25.
//

import SwiftUI

struct SignUpView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Create Account")
                .font(.title.bold())
                .padding(.top, 32)

            // Placeholder content; replace with real fields later
            Text("Sign up form goes here")
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("Signup")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack { SignUpView() }
}
