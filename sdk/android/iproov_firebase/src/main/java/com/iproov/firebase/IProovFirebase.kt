package com.iproov.firebase

import android.content.Context
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.TaskCompletionSource
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.functions.FirebaseFunctions

import com.iproov.sdk.api.IProov
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.onSubscription
import kotlinx.coroutines.tasks.await

private const val defaultRegion = "us-central1"
private const val defaultExtensionId = "auth-iproov"

class IProovPrivacyPolicyDeniedException : Exception("User declined privacy policy")

enum class AssuranceType(val value: String) {
    LIVENESS("liveness"),
    GENUINE_PRESENCE("genuine_presence")
}

enum class ClaimType(val value: String) {
    ENROL("enrol"),
    VERIFY("verify"),
}

fun FirebaseAuth.iProov(region: String = defaultRegion, extensionId: String = defaultExtensionId) =
    IProovFirebaseAuth(this, extensionId, region)

class IProovFirebaseAuth(
    private val functions: FirebaseFunctions,
    private val auth: FirebaseAuth,
    private val extensionId: String
) {

    constructor(
        auth: FirebaseAuth,
        extensionId: String = defaultExtensionId,
        region: String = defaultRegion
    ) : this(
        FirebaseFunctions.getInstance(auth.app, region),
        auth,
        extensionId
    )

    // Public API that returns Task<AuthResult>
    fun createUser(
        activity: AppCompatActivity,
        userId: String,
        iProovEvents: MutableStateFlow<IProov.State?>? = null,
        assuranceType: AssuranceType = AssuranceType.GENUINE_PRESENCE,
        iProovOptions: IProov.Options = IProov.Options(),
    ): Task<AuthResult> {
        return getTokenAndLaunchIProov(activity, userId, iProovEvents, assuranceType, ClaimType.ENROL, iProovOptions)
    }

    // Public API that returns Task<AuthResult>
    fun signIn(
        activity: AppCompatActivity,
        userId: String,
        iProovEvents: MutableStateFlow<IProov.State?>? = null,
        assuranceType: AssuranceType = AssuranceType.GENUINE_PRESENCE,
        iProovOptions: IProov.Options = IProov.Options(),
    ): Task<AuthResult> {
        return getTokenAndLaunchIProov(activity, userId, iProovEvents, assuranceType, ClaimType.VERIFY, iProovOptions)
    }

    // Private method that handles the coroutine logic internally and returns Task<AuthResult>
    private fun getTokenAndLaunchIProov(
        activity: AppCompatActivity,
        userId: String,
        iProovEvents: MutableStateFlow<IProov.State?>?,
        assuranceType: AssuranceType,
        claimType: ClaimType,
        iProovOptions: IProov.Options
    ): Task<AuthResult> {

        val taskCompletionSource = TaskCompletionSource<AuthResult>()

        // Start coroutine internally
        CoroutineScope(Dispatchers.Default).launch {
            try {
                // Get token using coroutine (suspend function)
                val response = getToken(userId, assuranceType, claimType)

                val region = response["region"] as String
                val token = response["token"] as String
                val privacyPolicyUrl = response["privacyPolicyUrl"] as String?

                if (privacyPolicyUrl != null) {

                    // Show privacy policy dialog
                    val dialog = PrivacyPolicyDialog.newInstance(privacyPolicyUrl)
                    dialog.setOnDialogResultListener(object : PrivacyPolicyDialog.ResultListener {
                        override fun onAccept() {
                            // Launch IProov if the privacy policy is accepted
                            CoroutineScope(Dispatchers.Default).launch {
                                launchIProov(
                                    activity,
                                    region,
                                    token,
                                    userId,
                                    claimType,
                                    iProovOptions,
                                    iProovEvents,
                                    taskCompletionSource
                                )
                            }
                        }

                        override fun onDecline() {
                            taskCompletionSource.setException(IProovPrivacyPolicyDeniedException())
                        }
                    })
                    dialog.show(activity.supportFragmentManager, "PrivacyPolicyActivity")

                } else {
                    // No privacy policy, directly launch IProov
                    launchIProov(
                        activity,
                        region,
                        token,
                        userId,
                        claimType,
                        iProovOptions,
                        iProovEvents,
                        taskCompletionSource
                    )
                }
            } catch (e: Exception) {
                taskCompletionSource.setException(e)
            }
        }

        // Return the Task to the caller
        return taskCompletionSource.task
    }

    private suspend fun getToken(
        userId: String,
        assuranceType: AssuranceType,
        claimType: ClaimType
    ): Map<*, *> {
        val response = functions
            .getHttpsCallable("ext-$extensionId-getToken")
            .call(
                mapOf(
                    "assuranceType" to assuranceType.value,
                    "claimType" to claimType.value,
                    "userId" to userId,
                )
            ).await()

        return response.data as Map<*, *>
    }

    private suspend fun launchIProov(
        context: Context,
        region: String,
        token: String,
        userId: String,
        claimType: ClaimType,
        iProovOptions: IProov.Options,
        iProovEvents: MutableStateFlow<IProov.State?>?,
        taskCompletionSource: TaskCompletionSource<AuthResult>
    ) {
        val session = IProov.createSession(
            context,
            "wss://$region.rp.secure.iproov.me/ws",
            token,
            iProovOptions
        )

        CoroutineScope(Dispatchers.Default).launch {
            session.state
                .onSubscription { session.start() }
                .collect { state ->
                    iProovEvents?.emit(state)
                    if (state is IProov.State.Success) {
                        try {
                            val result = validate(userId, token, claimType)
                            taskCompletionSource.setResult(result)
                        } catch (e: Exception) {
                            taskCompletionSource.setException(e)
                        } finally {
                            this.cancel()
                        }
                    }
                }
        }.join()
    }

    private suspend fun validate(
        userId: String,
        token: String,
        claimType: ClaimType
    ): AuthResult {
        val response = functions
            .getHttpsCallable("ext-$extensionId-validate")
            .call(
                mapOf(
                    "userId" to userId,
                    "token" to token,
                    "claimType" to claimType.value,
                )
            ).await()

        val jwt = response.data as String
        return auth.signInWithCustomToken(jwt).await()
    }
}
