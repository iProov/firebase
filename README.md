# iProov Firebase Auth Extension

Welcome to the iProov Firebase Auth Extension!

The iProov Firebase Auth Extension allows you to use iProov Biometrics to authenticate your app's users with Firebase Auth.

It consists of:

- An installable [Firebase Extension](https://github.com/iProov/firebase/tree/master/extension) that you can add to your Firebase project.
- [Mobile SDKs](https://github.com/iProov/firebase/tree/master/sdk) that you can add to your mobile app to perform the iProov face scan (iOS, Android and Flutter are currently supported).

## Installing on Firebase

Follow the instructions [here](https://github.com/iProov/firebase/blob/master/extension/PREINSTALL.md).

## Installing locally on emulator

The extension can be emulated locally for development & testing.

1. [Setup your machine with the emulator](https://firebase.google.com/docs/functions/local-emulator).

    > **IMPORTANT:** [You **must** setup `GOOGLE_APPLICATION_CREDENTIALS`](https://firebase.google.com/docs/functions/local-emulator#set_up_admin_credentials_optional), otherwise you will get errors when making requests through the extension.

    ```sh
    npm install -g firebase-tools
    export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json" # Make sure you set this!
    ```

3. Start the emulator:

    ```sh
    cd extension/local    
    firebase emulators:start --project <project-id>
    ```

## Deploying to Firebase

### Deploying a local copy (for testing)

```sh
cd extension
firebase ext:dev:upload iproov/auth-iproov --local
```

### Deploying to production

```sh
firebase ext:dev:upload iproov/auth-iproov
```