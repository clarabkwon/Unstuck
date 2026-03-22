// UnstuckApp.swift — app entry point
// Unstuck

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct Unstuck: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appData = AppData()

    var body: some Scene {
        WindowGroup {
            if appData.hasCheckedInToday {
                // Already checked in today — go straight to home
                NavigationStack { ContentView() }
                    .environmentObject(appData)
            } else {
                // First open of the day — run the 3-step check-in
                CheckInView()
                    .environmentObject(appData)
            }
        }
    }
}
