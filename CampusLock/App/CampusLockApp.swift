import SwiftUI

@main
struct CampusLockApp: App {
    @State private var store = CampusLockStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
