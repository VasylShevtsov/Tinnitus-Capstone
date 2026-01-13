//
//  ContentView.swift
//  Tinnitus Capstone
//
//  Created by Basil Shevtsov on 10/4/25.
//


import SwiftUI
struct ContentView: View {
    @State private var isLoggedIn = false //tracks whether the user is logged in. holder until backend is paired

    var body: some View {
        NavigationStack { //nav environment, push pop screens
            if isLoggedIn { //decides which screen to show
                HomeView()
            } else {
                //SignUpOrLoginView()
                //HomeView()
                LoginView()
                //LoudnessMatchView()
                //SignUpOrLoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}

#Preview {
    ContentView()
}
/*
 Launch App
↓
Check if user isLoggedIn
↓
If false → show SignUpLogInView
If true  → show HomeView
*/
