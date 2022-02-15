//
//  iosStudiaApp.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/06.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct iosStudiaApp: App {
    init() {
        FirebaseApp.configure()
        
        // Set default value for settings
        UserDefaults.standard.register(defaults: [
            "persistence": true
        ])
        
        // Set persistence for firebase database
        Database.database().isPersistenceEnabled = UserDefaults.standard.bool(forKey: "persistence")
    }
    
    var body: some Scene {
        WindowGroup {
            if Auth.auth().currentUser != nil {
                CalendarView()
            } else {
                LoginView()
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
            }
        }
    }
}
