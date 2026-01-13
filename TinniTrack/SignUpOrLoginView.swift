//
//  SignUpView.swift
//  Tinnitus Capstone
//
//  Created by Anika Patel on 11/10/25.
//

import SwiftUI

struct SignUpView: View {
    @State private var email: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Main content
            VStack(spacing: 24) {
                // Header text
                VStack(spacing: 2) {
                    Text("Create an account")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("Enter your email to sign up for this app")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                
                // Email input and button
                VStack(alignment: .leading, spacing: 16) {
                    // Email text field
                    TextField("email@domain.com", text: $email)
                        .font(.system(size: 14))
                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .frame(height: 40)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.88, green: 0.88, blue: 0.88), lineWidth: 1)
                        )
                    
                    // Sign up button
                    Button(action: {
                        // Handle sign up with email
                        print("Sign up with email: \(email)")
                    }) {
                        Text("Sign up with email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.black)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                
                // Divider with text
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color(red: 0.90, green: 0.90, blue: 0.90))
                        .frame(height: 1)
                    
                    Text("or continue with")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    
                    Rectangle()
                        .fill(Color(red: 0.90, green: 0.90, blue: 0.90))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)
                
                // Google button
                Button(action: {
                    // Handle Google sign in
                    print("Sign up with Google")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .frame(width: 20, height: 20)
                        
                        Text("Google")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.88, green: 0.88, blue: 0.88), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                
                // Terms text
                Text("By clicking continue, you agree to our Terms of Service and Privacy Policy")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Home indicator (bottom bar)
            Rectangle()
                .fill(Color.black)
                .frame(width: 134, height: 5)
                .cornerRadius(100)
                .padding(.bottom, 8)
        }
        .background(Color.white)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
