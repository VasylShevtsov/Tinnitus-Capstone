//
//  Tinnitus_CapstoneApp.swift
//  Tinnitus Capstone
//
//  Created by Basil Shevtsov on 10/4/25.
//

import SwiftUI
import Spezi

@main
struct Tinnitus_CapstoneApp: App {
    @ApplicationDelegateAdaptor(TinnitusCapstoneDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .spezi(appDelegate)
        }
    }
}
