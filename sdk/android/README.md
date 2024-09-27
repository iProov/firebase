# iProov Firebase Android SDK

## Requirements

Before you can use this SDK, you will need to:

- Create a Firebase project in the [Firebase console](https://console.firebase.google.com)
- Register your app with Firebase
- Download the `google-services.json` file and add it to your project
- Add the iProov Firebase Android SDK to your project

Now you can add the iProov Firebase Android SDK to your project.

## Installation

The iProov Firebase Android SDK is provided in Android Library Project (AAR) format as a Maven dependency.


1. Open the `build.gradle` file corresponding to the new, or existing, Android Studio project that you want to integrate. Typically, this is the `build.gradle` file for the `app` module.

2. Add maven to the `repositories` section in your `build.gradle` file:

    ```groovy
    repositories {
        maven { url 'https://raw.githubusercontent.com/iProov/firebase/master/android/maven/' }
    }
    ```

3. Add the SDK version to the `dependencies` section in your `build.gradle` file:

    ```groovy
    dependencies {
        implementation('com.iproov.firebase:iproov-firebase:1.0.0')
    }
    ```

4. Add support for Java 8 to your `build.gradle` file. Skip this step if Java 8 is enabled:

    ```groovy
    android {
        compileOptions {
            sourceCompatibility JavaVersion.VERSION_1_8
            targetCompatibility JavaVersion.VERSION_1_8
        }
    }
    ```

5. Build your project


## Usage

### Basic example

To register an iProov user using Genuine Presence Assurance with the default settings:

```kotlin

class MainActivity : ComponentActivity() {

    companion object {
        val iProovEvents: MutableStateFlow<IProov.IProovSessionState?> = MutableStateFlow(null)
    }

    override fun onStart() {
        super.onStart()
        mAuthListener = FirebaseAuth.AuthStateListener { firebaseAuth ->
            print("FirebaseAuth state changed: ${firebaseAuth.currentUser}")
        }

        FirebaseAuth.getInstance().addAuthStateListener(mAuthListener!!)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        FirebaseApp.initializeApp(this)
        super.onCreate(savedInstanceState)

        setContent {
            Page()
        }

        lifecycleScope.launch(Dispatchers.Default) {
            repeatOnLifecycle(Lifecycle.State.CREATED) {
                iProovEvents.collect { sessionState: IProov.IProovSessionState? ->
                    sessionState?.state?.let { state ->
                        withContext(Dispatchers.Main) {
                            print("IProov state: $state")
                        }
                    }
                }
            }
        }
    }

    private fun createUser() = CoroutineScope(Dispatchers.IO).launch {
        FirebaseAuth.getInstance().iProov()
            .createUser(applicationContext, "johnsmith@example.com", iProovEvents)
    }

    private fun signIn() = CoroutineScope(Dispatchers.IO).launch {
        FirebaseAuth.getInstance().iProov()
            .signIn(applicationContext, "johnsmith@example.com", iProovEvents)
    }
}
```

### Advanced example

Once you've got up and running with the basic example, you can now pass additional parameters
to `createUser()` and `signIn()`:

- `assuranceType` - specify the assurance type (Genuine Presence Assurance or Liveness Assurance)
- `iProovOptions` - customize
  any [iProov SDK options](https://github.com/iproov/ios?tab=readme-ov-file#options)

Here's an example of modifying the above createUser function, creating an iProov user with Liveness
Assurance and specifying a custom title for the face scan and the extension.

```kotlin
private fun register() = CoroutineScope(Dispatchers.IO).launch {
    FirebaseAuth.getInstance().iProov().createUser(
        applicationContext,
        "johnsmith@example.com",
        iProovEvents,
        assuranceType = AssuranceType.LIVENESS,
        iproovOptions = IProov.Options().apply {
            title = "Firebase Auth Example"
        }

    )
}
```

You can also pass additional parameters to `FirebaseAuth.getInstance().iProov()` if your extension
ID is anything other than `iproov-auth` and/or your extension is installed in a region other
than `us-central1`, e.g.:

```kotlin
FirebaseAuth.getInstance().iProov(region = "europe-west2", extensionId = "iproov-auth-eu")
```

## Example App

In the `example-app` folder, you'll find an example implementation of the iProov Firebase Android
SDK.

1. Download the google-services.json file from Firebase and add it to the `example-app/` directory.
2. Open the `example-app` directory in Android Studio.
3. Update the line `applicationId = "com.iproov.firebase.example"` to match the package name specified in your `google-services.json` file.

## Further reading

Consult the documentation for
the [iProov Biometrics Android SDK](https://github.com/iProov/android).