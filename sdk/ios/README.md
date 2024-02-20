# iProov Firebase iOS SDK

## Requirements

- iOS 12.0 and above
- Xcode 14.1 and above

## Installation

iProovFirebase is available as a locally-installable Cocoapod.

To install it, simply add the following line to your Podfile:

```ruby
pod 'iProovFirebase', :path => 'path/to/iProovFirebase'
```

### Add an `NSCameraUsageDescription`

All iOS apps which require camera access must request permission from the user, and specify this information in the Info.plist.

Add an `NSCameraUsageDescription` entry to your app's Info.plist, with the reason why your app requires camera access (e.g. “To iProov you in order to verify your identity.”)

## Usage

The iProov Firebase SDK extends Firebase Auth with support for creating and signing in users using iProov Biometrics.

### Basic example

To register an iProov user using Genuine Presence Assurance with the default settings:

```swift
Auth.auth().createUser(withIProovUserID: "hello@world.com") { result, error in
    if let error = error {
        print("Error: \(error)")
        return
    }

    if let user = result?.user {
        print("User ID: \(user.uid))
    }
}
```

To sign in an existing user, simply use `Auth.auth().signIn(withIProovUserID:)` and pass their `userID`.

### Advanced example

Once you've got up and running with the basic example, you can now pass additional parameters to `createIProovUser()` and `signInIProovUser()`:

- `assuranceType` - specify the assurance type (Genuine Presence Assurance or Liveness Assurance)
- `options` - customize any [iProov SDK options](https://github.com/iproov/ios?tab=readme-ov-file#options)
- `extensionID` - if you have more than one instance of the iProov Extension installed or the extension ID is anything other than `auth-iproov`, you can override it here
- `progressCallback` - progress callbacks from iProov indicating face scan progress

Here's an example, creating an iProov user with Liveness Assurance, specifying a custom title for the face scan and listening to the iProov SDK callback events:

```swift
let options = Options()
options.title = "Firebase Auth Example"

Auth.auth().createUser(withIProovUserID: "hello@world.com",
                       assuranceType: .liveness,
                       options: options,
                       progressCallback: { progress in
    print(progress)
}) { result, error in
    if let error = error {
        print("Error: \(error)")
        return
    }

    if let user = result?.user {
        print("User ID: \(user.uid))
    }
}
```

## Example app

In the `Example` folder, you'll find an example implementation of the iProov Firebase Auth iOS SDK.

1. Download the `GoogleService-Info.plist` file from Firebase and add it to the `Example/iProovFirebase` directory.

2. Open the `iProovFirebase.xcworkspace` file and build & run the project.

## Further reading

Consult the documentation for the [iProov Biometrics iOS SDK](https://github.com/iProov/ios).