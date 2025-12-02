import Spezi
import SwiftUI

class TinnitusCapstoneDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: TinnitusCapstoneStandard()) {
            // Add your Spezi modules here
            // e.g.:
            // account
            // healthKit
        }
    }
}
