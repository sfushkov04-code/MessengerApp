//
//  ChatAppApp.swift
//  ChatApp
//
//  Created by Fushkov on 28.03.2026.
//

import SwiftUI
import Firebase

@main
struct ChatAppApp: App {
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
