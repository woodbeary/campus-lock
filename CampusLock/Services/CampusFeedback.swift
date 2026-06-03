import AudioToolbox
import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum CampusFeedback {
    @MainActor
    static func locked() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        AudioServicesPlaySystemSound(1057)
    }

    @MainActor
    static func unlocked() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.85)
        #endif
    }

    @MainActor
    static func outsideZone() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}
