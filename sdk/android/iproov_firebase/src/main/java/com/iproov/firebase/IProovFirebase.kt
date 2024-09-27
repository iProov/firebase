package com.iproov.firebase

import android.content.Context
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.TaskCompletionSource
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.functions.FirebaseFunctions

import com.iproov.sdk.api.IProov
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.onSubscription
import kotlinx.coroutines.launch
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

    suspend fun createUser(
        activity: AppCompatActivity,
        userId: String,
        iProovEvents: MutableStateFlow<IProov.State?>? = null,
        assuranceType: AssuranceType = AssuranceType.GENUINE_PRESENCE,
        iProovOptions: IProov.Options = IProov.Options(),
    ) {
        return getTokenAndLaunchIProov(
            activity,
            userId,
            iProovEvents,
            assuranceType,
            ClaimType.ENROL,
            iProovOptions,
        )
    }

    suspend fun signIn(
        activity: AppCompatActivity,
        userId: String,
        iProovEvents: MutableStateFlow<IProov.State?>? = null,
        assuranceType: AssuranceType = AssuranceType.GENUINE_PRESENCE,
        iProovOptions: IProov.Options = IProov.Options(),
    ) {

        return getTokenAndLaunchIProov(
            activity,
            userId,
            iProovEvents,
            assuranceType,
            ClaimType.VERIFY,
            iProovOptions,
        )
    }

    private suspend fun validate(
        userId: String,
        token: String,
        claimType: ClaimType,
    ): Task<AuthResult> {

        val response =
            functions
                .getHttpsCallable("ext-${extensionId}-validate")
                .call(
                    mapOf(
                        "userId" to userId,
                        "token" to token,
                        "claimType" to claimType.value,
                    )
                )
                .await()

        val jwt = response.data as String
        return auth.signInWithCustomToken(jwt)
    }

    private suspend fun getTokenAndLaunchIProov(
        activity: AppCompatActivity,
        userId: String,
        iProovEvents: MutableStateFlow<IProov.State?>?,
        assuranceType: AssuranceType,
        claimType: ClaimType,
        iproovOptions: IProov.Options,
    ) {

        val response =
            functions
                .getHttpsCallable("ext-${extensionId}-getToken")
                .call(
                    mapOf(
                        "assuranceType" to assuranceType.value,
                        "claimType" to claimType.value,
                        "userId" to userId,
                    )
                )
                .await()

        val data = response.data as Map<*, *>

        val region = data["region"] as String
        val token = data["token"] as String
        val privacyPolicyUrl = data["privacyPolicyUrl"] as String?

        if (privacyPolicyUrl != null) {
            Log.i("iProov", "LAUNCH Privacy Policy URL: $privacyPolicyUrl")

            val dialog = PrivacyPolicyDialog.newInstance(privacyPolicyUrl)
            dialog.setOnDialogResultListener(object : PrivacyPolicyDialog.ResultListener {
                override fun onAccept() {
                    CoroutineScope(Dispatchers.Default).launch {
                        launchIProov(activity, region, token, userId, claimType, iproovOptions, iProovEvents)
                    }
                }

                override fun onDecline() {
                    throw IProovPrivacyPolicyDeniedException()
                }
            })
            dialog.show(activity.supportFragmentManager, "PrivacyPolicyActivity")

        } else {
            launchIProov(activity, region, token, userId, claimType, iproovOptions, iProovEvents)
        }

    }

    private suspend fun launchIProov(context: Context,
                                     region: String,
                                     token: String,
                                     userId: String,
                                     claimType: ClaimType,
                                     iProovOptions: IProov.Options,
                                     iProovEvents: MutableStateFlow<IProov.State?>?) {

        val session: IProov.Session = IProov.createSession(
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
                        validate(userId, token, claimType).await()
                        this.cancel()
                    }
                }
        }.join()
    }

}
