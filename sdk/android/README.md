# iProov Firebase Android SDK

## Requirements

Before you can use this SDK, you will need to:

- Create a Firebase project in the [Firebase console](https://console.firebase.google.com)
- Register your app with Firebase
- Download the `google-services.json` file and add it to your project
- Add the iProov Firebase Android SDK to your project

Now you can add the iProov Firebase Android SDK to your project.

## Installation

## Supported Functionality

- **`createIProovUser()`** - Create an iProov user
- **`signInWithIProov()`** - Sign in with an iProov user

## Example

Example of basic usage of the iProov Firebase Android SDK:

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

    private fun register() = CoroutineScope(Dispatchers.IO).launch {
        FirebaseAuth.getInstance()
            .createIProovUser(applicationContext, "johnsmith@example.com", iProovEvents);
    }

    private fun login() = CoroutineScope(Dispatchers.IO).launch {
        FirebaseAuth.getInstance()
            .signInWithIProov(applicationContext, "johnsmith@example.com", iProovEvents);
    }
}
```

## Example App

The Example App included, written in Kotlin with Coroutines, demonstrates the use of the iProov Firebase Android SDK.

Download the google-services.json file from Firebase and add it to the example-app directory.

## Further reading

Consult the documentation for the [iProov Biometrics Android SDK](https://github.com/iProov/android).