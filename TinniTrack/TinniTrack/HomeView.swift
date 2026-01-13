//
//  HomeView.swift
//  Tinnitus Capstone
//
//  Created by Anika Patel on 11/10/25.
//

import SwiftUI

struct HomeView: View {
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with menu and title
            HStack {
                Button(action: {
                    // Handle menu tap
                    print("Menu tapped")
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("HOME")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Empty space for symmetry
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.51))
                
                Text("Search")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.51))
                
                Spacer()
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 16))
            .frame(height: 40)
            .background(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.88, green: 0.88, blue: 0.88), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Quick Actions header
            Text("QUICK ACTIONS")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.black)
                .padding(.top, 32)
                .padding(.bottom, 16)
            
            // Quick Actions buttons (2x2 grid)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // FAQs button
                    Button(action: {
                        print("FAQs tapped")
                    }) {
                        Text("FAQs")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(width: 163, height: 98)
                            .background(.white)
                            .cornerRadius(30)
                    }
                    
                    // Settings button
                    Button(action: {
                        print("Settings tapped")
                    }) {
                        Text("SETTINGS")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(width: 164, height: 98)
                            .background(.white)
                            .cornerRadius(30)
                    }
                }
                
                HStack(spacing: 12) {
                    // Patient History button
                    Button(action: {
                        print("Patient History tapped")
                    }) {
                        Text("PATIENT\nHISTORY")
                            .font(.system(size: 20, weight: .heavy))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                            .frame(width: 164, height: 98)
                            .background(.white)
                            .cornerRadius(30)
                    }
                    
                    // Therapy button
                    Button(action: {
                        print("Therapy tapped")
                    }) {
                        Text("THERAPY")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(width: 164, height: 98)
                            .background(.white)
                            .cornerRadius(30)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Loudness Matching button
            // Loudness Matching button - navigates to LoudnessMatchView
            NavigationLink(destination: LoudnessMatchView()) {
                Text("LOUDNESS MATCHING")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.black)
                    .frame(width: 356, height: 171)
                    .background(.white)
                    .cornerRadius(30)
            }
            .padding(.bottom, 20)
            
            // Home indicator (bottom bar)
            Rectangle()
                .fill(Color.black)
                .frame(width: 134, height: 5)
                .cornerRadius(100)
                .padding(.bottom, 8)
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .navigationBarHidden(true)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
