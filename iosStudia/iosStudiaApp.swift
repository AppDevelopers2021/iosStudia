import SwiftUI
import Firebase
import GoogleSignIn

@main
struct iosStudiaApp: App {
    init() {
        FirebaseApp.configure()
        
        // Set default value
        UserDefaults.standard.register(defaults: [
            "persistence": true,                // Persistence in user preferences
            "isAppAlreadyLaunchedOnce": false   // For showing TurorialView at first launch
        ])
        
        // Set persistence for firebase database
        Database.database().isPersistenceEnabled = UserDefaults.standard.bool(forKey: "persistence")
    }
    
    var body: some Scene {
        WindowGroup {
            if UserDefaults.standard.bool(forKey: "isAppAlreadyLaunchedOnce") {
                if Auth.auth().currentUser != nil {
                    CalendarView()
                } else {
                    LoginView()
                        .onOpenURL { url in
                            // Handle URL after Google Signin
                            GIDSignIn.sharedInstance.handle(url)
                        }
                }
            } else {
                // App launched for the first time
                // Show tutorial view
                TurorialView()
            }
            
        }
    }
}
