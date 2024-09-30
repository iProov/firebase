package com.iproov.firebase.example_app

import android.os.Bundle
import android.util.Log
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.lifecycleScope
import com.google.android.gms.tasks.Task
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.iproov.firebase.AssuranceType
import com.iproov.firebase.example_app.ui.theme.Iproov_firebaseTheme
import com.iproov.firebase.iProov
import com.iproov.sdk.api.IProov
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

data class PageState(val user: FirebaseUser? = null, val isLoading: Boolean = false)

class MainActivity : AppCompatActivity() {

    private var pageState = PageState()
    private var mAuthListener: FirebaseAuth.AuthStateListener? = null

    companion object {
        val iProovEvents: MutableStateFlow<IProov.State?> = MutableStateFlow(null)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        FirebaseApp.initializeApp(this)
        super.onCreate(savedInstanceState)
        setState(pageState)
        observeIProovEvents()
    }

    private fun observeIProovEvents() {
        lifecycleScope.launch(Dispatchers.IO) {
            iProovEvents
                .collect { state ->
                    Log.i("iProov", "State: $state")
                    setState(pageState.copy(isLoading = !(state?.isFinal ?: true)))
                }
        }
    }

    private fun setState(state: PageState) {
        pageState = state
        setContent {
            Page(state = pageState)
        }
    }

    override fun onStart() {
        super.onStart()
        mAuthListener =
            FirebaseAuth.AuthStateListener { firebaseAuth ->
                setState(pageState.copy(user = firebaseAuth.currentUser))
            }
        FirebaseAuth.getInstance().addAuthStateListener(mAuthListener!!)
    }

    override fun onStop() {
        mAuthListener?.let { listener ->
            FirebaseAuth.getInstance().removeAuthStateListener(listener)
        }
        super.onStop()
    }

    private fun register(userId: String, assuranceType: AssuranceType) {

        FirebaseAuth.getInstance()
            .iProov(extensionId = "auth-iproov-4nee")
            .createUser(
                this,
                userId,
                iProovEvents,
                assuranceType,
                IProov.Options().apply { title = "Firebase Auth Example" }
            ).addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    Log.i("iProov", "User created successfully")
                } else {
                    Log.e("iProov", "Error: ${task.exception?.message}")
                }
            }
    }

    private fun login(userId: String, assuranceType: AssuranceType) {

        FirebaseAuth.getInstance()
            .iProov(extensionId = "auth-iproov-4nee")
            .signIn(
                this,
                userId,
                iProovEvents,
                assuranceType,
                IProov.Options().apply { title = "Firebase Auth Example" }
            ).addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    Log.i("iProov", "User signed in successfully")
                } else {
                    Log.e("iProov", "Error: ${task.exception?.message}")
                }
            }
    }

    @Composable
    fun Page(state: PageState) {
        var userId by remember { mutableStateOf(UUID.randomUUID().toString()) }

        Iproov_firebaseTheme {
            // A surface container using the 'background' color from the theme
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                Column(
                    verticalArrangement = Arrangement.Top,
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(
                        "Firebase Android SDK Example App",
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.headlineSmall
                    )

                    if (state.isLoading) {
                        CircularProgressIndicator()
                        Text("Loading...", textAlign = TextAlign.Center)
                    } else {
                        TextField(
                            value = userId,
                            onValueChange = { userId = it },
                            label = { Text("User ID") }
                        )

                        Button(onClick = { register(userId, AssuranceType.GENUINE_PRESENCE) }) { Text("Register with Genuine Presence Assurance") }
                        Button(onClick = { register(userId, AssuranceType.LIVENESS) }) { Text("Register with Liveness Assurance") }
                        Button(onClick = { login(userId, AssuranceType.GENUINE_PRESENCE) }) { Text("Login with Genuine Presence Assurance") }
                        Button(onClick = { login(userId, AssuranceType.LIVENESS) }) { Text("Login with Liveness Assurance") }

                        if (state.user != null) {
                            Button(onClick = { FirebaseAuth.getInstance().signOut() }) {
                                Text("Sign out")
                            }
                        }
                    }
                }
            }
        }
    }
}
