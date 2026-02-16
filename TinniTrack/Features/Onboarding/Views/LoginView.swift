//
//  LoginView.swift
//  Tinnitus Capstone
//
//

import SwiftUI

struct LoginView: View {
    
    var body: some View {
        VStack(spacing: 0) {
            // Top spacer
            Spacer()
            
            // App title (no border)
            Text("CALM\nTINNITUS")
                .font(.system(size: 40, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                .padding(.bottom, 80)
            
            // Signup button - navigates to SignUpView
            NavigationLink(destination: SignUpView()) {
                Text("Signup")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Login button - you can add navigation later
            NavigationLink(destination: HomeView()) {
                Text("Login")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            
            // Bottom spacer
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
