# Spezi Documentation Compilation

## Overview

Spezi is an open-source framework for rapid development of modern,
interoperable digital health applications. It introduces a
standards-based modular approach to building digital health
applications. The framework relies on an ecosystem of modules, ranging
from standalone functionality using frameworks like Swift or SwiftUI to
complex functionality involving user interfaces and data management.

## Essential Concepts

The framework is built upon two fundamental building blocks:

### Standard

A Standard defines the key coordinator that orchestrates the data flow
in the application by meeting requirements defined by modules. It
conforms to the `Standard` protocol.

### Module

A Module defines a software subsystem providing distinct and reusable
functionality that can be configured as part of the configuration.
Modules can use the constraint mechanism to enforce a set of
requirements to the Standard used in the Spezi-based software where the
module is used. Modules also define dependencies on each other to reuse
functionality and can communicate with other modules by offering and
collecting information.

## Initial Setup

The Spezi framework can be integrated into any iOS application. You can
define which modules you want to integrate into the Spezi configuration.

### 1. Add the Spezi View Modifier

Set up the Spezi framework in your App instance of your SwiftUI
application using the `SpeziAppDelegate` and the
`@ApplicationDelegateAdaptor` property wrapper. Use the
`View.spezi(_: SpeziAppDelegate)` view modifier to apply your Spezi
configuration to the main view in your SwiftUI Scene.

``` swift
import Spezi
import SwiftUI

@main
struct ExampleApp: App {
    @ApplicationDelegateAdaptor(SpeziAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .spezi(appDelegate)
        }
    }
}
```

### 2. Modify Your Spezi Configuration

A `Configuration` defines the Standard and Modules that are used in a
Spezi project. Ensure that your standard conforms to all protocols
enforced by the Modules. If your Modules require protocol conformances
you must add them to your custom type conforming to Standard and passed
to the initializer or extend a prebuilt standard. Use `init` to use a
default empty standard instance only conforming to Standard if you do
not use any Module requiring custom protocol conformances.

The following example demonstrates the usage of an `ExampleStandard`
standard and reusable Spezi modules, including the HealthKit and
QuestionnaireDataSource modules:

``` swift
import Spezi
import SpeziHealthKit
import SpeziOnboarding
import SwiftUI

class ExampleAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: ExampleStandard()) {
            if HKHealthStore.isHealthDataAvailable() {
                HealthKit {
                    CollectSample(
                        HKQuantityType(.stepCount),
                        deliverySetting: .background(.afterAuthorizationAndApplicationWillLaunch)
                    )
                }
            }
            OnboardingDataSource()
        }
    }
}
```

## Configuration Structure

The `Configuration` struct defines the Standard and Modules that are
used in a Spezi project.

**Initializers:**

-   `init<S>(standard: S, _ modules: ModuleCollection)`: A Configuration
    defines the Standard and Modules that are used in a Spezi project.

**Result Builder:**

-   `enum ModuleBuilder`: A function builder used to aggregate multiple
    `Module`s.
-   `class ModuleCollection`: A `ModuleCollection` defines a collection
    of Modules.

## SpeziAppDelegate

The `SpeziAppDelegate` class is used to configure the Spezi-based
application using the configuration property. It inherits from
`ObjectiveC.NSObject` and conforms to `UIKit.UIApplicationDelegate`.

**Instance Properties:**

-   `var configuration: Configuration`: Register your different Modules
    (or more sophisticated Modules) using the configuration property.

**Instance Methods:**

-   `func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration`
-   `func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)`
-   `func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult`
-   `func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)`
-   `func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool`
-   `func applicationWillTerminate(_ application: UIApplication)`

## Standard Implementation

The Standard is the key module that orchestrates the data flow within
the application and is provided upon App configuration.

### Standard Constraints

Modules can use the constraint mechanism to enforce a set of
requirements to the Standard used in the Spezi-based software where the
module is used. This mechanism follows a two-step process. The
constraints are defined using a protocol that conforms to the Standard
protocol.

**Defining a Constraint:** Define a standard constraint required by your
module. The constraint protocol must conform to the Standard protocol.

``` swift
protocol ExampleConstraint: Standard {
}
```

**Enforcing and Applying the Constraint:** Use the constraint in your
module to access the Standard instance that conforms to the protocol.

``` swift
class ExampleModule: Module {
    @StandardActor var standard: any ExampleConstraint
}
```

### Standard Conformance

The Standard defined in the Configuration must conform to all
constraints defined by Modules using their `@StandardActor`s, or you
need to write an extension to an existing Standard that you use to
implement the conformance. You will have to define your own Standard
type or use a predefined one that either conforms to all requirements or
is extended to support these requirements using Swift extensions if your
application uses any modules that enforce constraints on the Standard
Instance.

**Defining your own Standard:**

If you define your own standard, you can define the conformance and
complete implementation in your code:

``` swift
actor ExampleStandard: Standard, ExampleConstraint {
}
```

**Extending a Predefined Standard:**

If you use a predefined standard, you can extend it using Swift
extensions if it does not yet support the required module constraints:

``` swift
extension ExistingStandard: ExampleConstraint {
}
```

**Accessing Standard:**

You can always access the current Standard instance in your Module using
the `@StandardActor` property wrapper. It is also available using the
`@Environment` property wrapper in your SwiftUI views when you declare
conformance to `EnvironmentAccessible`.

## Module Implementation

A `Module` defines a software subsystem that can be configured as part
of the configuration.

### Configuration and Lifecycle

A Module's initializer can be used to configure its behavior as a
subsystem in Spezi-based software. A Module is placed into the
Configuration section of your App to enable and configure it.

-   `func configure()`: Called on the initialization of the Spezi
    instance to perform a lightweight configuration of the module.
    -   **Tip:** It is advised that longer setup tasks are done in an
        asynchronous task and started during the call of the configure
        method.
    -   You can access `@StandardActor` once your `configure()` method
        is called and can continue to access the Standard actor in
        methods like `willFinishLaunchingWithOptions`.

### Capabilities

-   **Interactions with SwiftUI:** Interact with the SwiftUI view
    hierarchy and its environment.
-   **Interactions with Application:** Interact with the Application.
-   **Module Dependency:** Define dependence of Modules, establishing an
    order of initialization.
-   **Module Communication:** Establish data flow between Modules
    without establishing a dependency hierarchy.
-   **User Notifications:** Manage and respond to User Notifications
    within your App and Modules.

## Spezi Guide and Contributing

To be featured by the Spezi team, a module, as well as the surrounding
Swift Package and repository, MUST conform to the Spezi Guide. The
module, as well as the surrounding Swift Package and repository, MUST
conform to this guide within two months after changes have been
published.

### Repository Setup

-   **Standards:** A repository MUST be in full conformance to the
    GitHub Community Standards. The repository MUST follow the GitHub
    Flow with automated safeguards before merging the code.
-   **Versioning:** The repository MUST use semantic versioning and MUST
    have an initial version tagged using git releases.
-   **Files:**
    -   MUST use a comprehensive `.gitignore` file at the root of the
        repo.
    -   It is RECOMMENDED to use a `CONTRIBUTORS.md` file.
    -   It is RECOMMENDED to use a `CITATION.cff` file to make it
        possible to cite the repository.
    -   It is RECOMMENDED to use a tool to automatically generate
        digital object identifiers (DOIs) for release.

### Spezi Usage

-   A Spezi module MUST support the latest major Spezi version within
    two months after the release.
-   The module MUST use Spezi built-in features and integrate into the
    ecosystem of modules.
-   It is RECOMMENDED to contribute features to existing Spezi modules
    if they fit within the feature scope rather than creating a new
    module.
-   Different distinct functionalities under the umbrella of a Spezi
    module SHOULD be separated out into different targets.

### License & Open Source

-   The repository and all code making up the module and Swift Package
    MUST use an open-source license; it SHOULD use the MIT license.
-   The repository MUST conform to the REUSE specification. The
    conformance MUST be automatically checked.
-   It is RECOMMENDED to copy the license in a `LICENSE.md` file to the
    root of the repo.
-   Stale projects MAY not be considered in conformance with the Spezi
    module guidelines.

### Code Style

-   The Spezi repository MUST have a comprehensive and detailed style
    guide defined by a configuration file and tool. It is RECOMMENDED to
    use SwiftLint for Swift-related code style checks.
-   It is RECOMMENDED using the Stanford BDHG SwiftLint configuration.
-   The code MUST conform to the defined code style, checked
    automatically in a pull request (PR) and on the main branch.

### Testing

-   The Spezi repository MUST incorporate an automated testing setup,
    including unit tests and user interface (UI) tests if applicable.
-   The project code coverage MUST be automatically reported. The
    project MUST have a code coverage of at least 70% of the lines of
    code; it is RECOMMENDED that at least 80% are covered.
-   Conformance MUST be automatically checked using GitHub Actions.

### Documentation

-   The repository and all code making up the module and Swift Package
    MUST conform to the Documentation Guide. The documentation MUST be
    hosted and accessible.
-   It is RECOMMENDED to use a `.spi.yml` file at the root of the repo
    to configure the Swift Package Index setup.

### Previews

-   `var isPreviewSimulator: Bool`: Check if the current process is
    running in a simulator inside a Xcode preview.
-   `enum LifecycleSimulationOptions`: Options to simulate behavior for
    a LifecycleHandler in cases where there is no app delegate like in
    Preview setups.
