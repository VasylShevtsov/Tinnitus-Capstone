import Spezi
import SwiftUI

class TinnitusAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: TinnitusAppStandard()) {
            // Add your Spezi modules here
            // e.g.:
            // account
            // healthKit
        }
    }
}
