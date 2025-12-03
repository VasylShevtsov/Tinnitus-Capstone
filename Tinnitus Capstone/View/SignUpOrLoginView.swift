//
//  SignUpOrLogin.swift
//  Tinnitus Capstone
//
//  Created by Anika Patel on 11/10/25.
//

import SwiftUI

struct SignUpOrLoginView: View {
    @Binding var isLoggedIn: Bool   // <-- ADD THIS

        var body: some View {
            VStack {
                Text("Sign Up or Log in View")

                Button("Log In") {
                    isLoggedIn = false   // example action
                }
            }
        }
}
