//
//  AppRootView.swift
//  TinniTrack
//

import SwiftUI

struct AppRootView: View {
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            if isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    AppRootView()
}
