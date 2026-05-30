import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        configuration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        configuration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration()
    }

    private func configuration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.01, green: 0.01, blue: 0.02, alpha: 1),
            icon: UIImage(systemName: "lock.circle"),
            title: ShieldConfiguration.Label(text: "Focus active", color: .white),
            subtitle: ShieldConfiguration.Label(text: "Leave the class zone or unlock in Campus Lock.", color: UIColor(white: 0.72, alpha: 1)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Open Campus Lock", color: .white),
            primaryButtonBackgroundColor: UIColor.systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Close", color: UIColor(white: 0.72, alpha: 1))
        )
    }
}
