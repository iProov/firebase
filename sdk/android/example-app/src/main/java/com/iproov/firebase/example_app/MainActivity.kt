package com.iproov.firebase.example_app

import android.os.Bundle
import android.util.Log
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.lifecycleScope
import com.google.firebase.FirebaseApp
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

    private fun register() = CoroutineScope(Dispatchers.IO).launch {
        try {
            FirebaseAuth.getInstance()
                .iProov(extensionId = "auth-iproov-4nee")
                .createUser(
                    this@MainActivity,
                    "johnsmith@example.com",
                    iProovEvents,
                    assuranceType = AssuranceType.LIVENESS,
                    iproovOptions =
                    IProov.Options().apply { title = "Firebase Auth Example" }
                )
        } catch (e: Exception) {
            Log.e("iProov", "Error: ${e.message}")
        }
    }

    @Composable
    fun Page(state: PageState) {
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
                        "Firebase Auth Example",
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.headlineLarge
                    )

                    if (state.isLoading) {
                        Text("Loading...", textAlign = TextAlign.Center)
                    } else {
                        if (state.user == null) {
                            Button(onClick = { register() }) { Text("Register") }
                        } else {

                            Text(
                                "User is registered ${state.user.uid}",
                                textAlign = TextAlign.Center
                            )
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
