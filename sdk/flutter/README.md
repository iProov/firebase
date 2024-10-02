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
final stream = FirebaseAuth.instance.iProov().createUser(userId: 'testuser@example.com');

await for (IProovEvent event in stream) {
    print(event); 
    if (event is IProovFirebaseEventAuthenticationSuccess ){
        print('User has registered ${event.user}');
    }
}
```

To sign in an existing user, simply use FirebaseAuth.instance.iProov().signIn() and pass their userID:

```dart
final stream = FirebaseAuth.instance.iProov().signIn(userId: 'testuser@example.com');

await for (IProovEvent event in stream) {
    print(event); 
    if (event is IProovFirebaseEventAuthenticationSuccess ){
        print('User has authenticated ${event.user}');
    }
}
```

### Advanced example

Once you've got up and running with the basic example, you can now pass additional parameters to createUser() and signIn():

- `assuranceType` - specify the assurance type (Genuine Presence Assurance or Liveness Assurance)
- `options` - customize the [iProov SDK options](https://github.com/iproov/flutter?tab=readme-ov-file#options)

Here's an example, creating an iProov user with Liveness Assurance, specifying a custom title for the face scan and listening to the iProov SDK event stream.

```dart
FirebaseAuth.instance.iProov().createUser(
    userId: 'iproov-example-user-0001',
    assuranceType: AssuranceType.liveness,
    options: const Options(
        title: 'Firebase Auth Example'
    ),
);
```
You can also pass additional parameters to `FirebaseAuth.instance.iProov()` if your extension ID is anything other than `iproov-auth` and/or your extension is installed in a region other than `us-central1`, e.g.:

```dart
FirebaseAuth.instance.iProov(region: 'europe-west2', extensionId: 'auth-iproov-3bau').signIn(userId: 'testuser@example.com');
```

## Example app

To use the Example app located in the `example` folder, run the following:

```sh
flutterfire configure --project=<project-id>
```

You can then build and run the app.

## Further reading

Consult the documentation for the [iProov Biometrics Flutter SDK](https://github.com/iProov/flutter).