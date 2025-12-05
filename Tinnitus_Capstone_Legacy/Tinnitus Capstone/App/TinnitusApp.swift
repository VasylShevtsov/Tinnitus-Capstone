import SwiftUI

@main
struct TinnitusApp: App {
    @UIApplicationDelegateAdaptor(TinnitusAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
