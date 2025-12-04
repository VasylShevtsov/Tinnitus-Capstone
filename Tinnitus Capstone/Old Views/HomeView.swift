//
//  HomeView.swift
//  Tinnitus Capstone
//
//  Created by Anika Patel on 11/10/25.
//

import SwiftUI 

struct HomeView: View {
    
    var body: some View {
            Text("Home View")
        VStack(spacing: 20)  {
            Text("Hell Portland")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(Color.blue)
            
            TextField("Search", text: .constant(""))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)   
        }
    }
    
}
