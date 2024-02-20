# iProov Firebase Flutter SDK

## Requirements

To use this SDK within your Flutter application you will need to first install the iProov Firebase Auth Extension into your Firebase project and [setup your Flutter app with the Firebase SDK](https://firebase.google.com/docs/flutter/setup).

## Installation

Add the following lines to the `dependencies` section of your Flutter project's `pubspec.yaml` file:

```yaml
    iproov_firebase:   
        git:
            url: https://github.com/iproov/firebase
            path: sdk/flutter
```

### iOS installation

You must also add a `NSCameraUsageDescription` to your iOS app's Info.plist, with the reason why your app requires camera access (e.g. “To iProov you in order to verify your identity.”).

## Usage

The iProov Firebase SDK extends Firebase Auth with support for creating and signing in users using iProov Biometrics.

###  Basic example

To register an iProov user using Genuine Presence Assurance with the default settings:

```dart
final stream = FirebaseAuth.instance.createIProovUser(userId: 'testuser@example.com');

await for (IProovEvent event in stream) {
    print(event); 
    if (event is IProovEventAuthenticationSuccess ){
        print('User has authenticated ${event.user}');
    }
}
```

To sign in an existing user, simply use Auth.auth().signInIProovUser() and pass their userID:

```dart
final stream = FirebaseAuth.instance.signInWithIProov(userId: 'testuser@example.com');

await for (IProovEvent event in stream) {
    print(event); 
    if (event is IProovEventAuthenticationSuccess ){
        print('User has authenticated ${event.user}');
    }
}
```

### Advanced example

Once you've got up and running with the basic example, you can now pass additional parameters to createIProovUser() and signInIProovUser():

- `assuranceType` - specify the assurance type (Genuine Presence Assurance or Liveness Assurance)
- `iproovOptions` - customize the [iProov SDK options](https://github.com/iproov/flutter?tab=readme-ov-file#options)
- `extensionId` - if you have more than one instance of the iProov Extension installed or the extension ID is anything other than `auth-iproov`, you can override it here

Here's an example, creating an iProov user with Liveness Assurance, specifying a custom title for the face scan and listening to the iProov SDK event stream.

```dart
FirebaseAuth.instance.createIProovUser(
    userId: 'iproov-example-user-0001',
    assuranceType: AssuranceType.liveness,
    iproovOptions: const Options(
        title: 'Firebase Auth Example'
    ),
);
```

## Example app

To use the Example app located in the `example` folder, run the following:

```sh
flutterfire configure --project=<project-id>
```

You can then build and run the app.

## Further reading

Consult the documentation for the [iProov Biometrics Flutter SDK](https://github.com/iProov/flutter).