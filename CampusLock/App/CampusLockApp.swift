import SwiftUI
import UIKit

@main
struct CampusLockApp: App {
    @State private var store = CampusLockStore()

    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        tabAppearance.shadowColor = UIColor.separator.withAlphaComponent(0.16)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
