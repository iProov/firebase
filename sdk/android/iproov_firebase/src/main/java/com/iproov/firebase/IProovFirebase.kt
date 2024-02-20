package com.iproov.firebase

import android.content.Context
import com.google.android.gms.tasks.Task
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.functions.FirebaseFunctions
import com.iproov.sdk.IProov
import com.iproov.sdk.IProovFlowLauncher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

private const val defaultExtensionId = "auth-iproov"

enum class AssuranceType(val value: String) {
    LIVENESS("liveness"),
    GENUINE_PRESENCE("genuine_presence");
}

enum class ClaimType(val value: String) {
    ENROL("enrol"),
    VERIFY("verify"),
}

suspend fun FirebaseAuth.signInWithIProov(
    applicationContext: Context,
    userId: String,
    iProovEvents: MutableStateFlow<IProov.IProovSessionState?>? = null,
    assuranceType: AssuranceType = AssuranceType.GENUINE_PRESENCE,
    iProovOptions: IProov.Options = IProov.Options(),
    extensionId: String = defaultExtensionId,
) {
    return doIProov(
        applicationContext,
        userId,
        iProovEvents,
        assuranceType,
        ClaimType.VERIFY,
        iProovOptions,
        extensionId,
    )
}

suspend fun FirebaseAuth.createIProovUser(
    applicationContext: Context,
    userId: String,
    iProovEvents: MutableStateFlow<IProov.IProovSessionState?>? = null,
    assuranceType: AssuranceType = AssuranceType.GENUINE_PRESENCE,
    iproovOptions: IProov.Options = IProov.Options(),
    extensionId: String = defaultExtensionId,
) {
    return doIProov(
        applicationContext,
        userId,
        iProovEvents,
        assuranceType,
        ClaimType.ENROL,
        iproovOptions,
        extensionId,
    )
}

private suspend fun doIProov(
    applicationContext: Context,
    userId: String,
    iProovEvents: MutableStateFlow<IProov.IProovSessionState?>?,
    assuranceType: AssuranceType,
    claimType: ClaimType,
    iproovOptions: IProov.Options,
    extensionId: String,
) {
    val response =
        FirebaseFunctions.getInstance()
            .getHttpsCallable("ext-${extensionId}-getToken")
            .call(
                mapOf(
                    "assuranceType" to assuranceType.value,
                    "claimType" to claimType.value,
                    "userId" to userId,
                )
            ).await()

    val data = response.data as Map<*, *>

    val region = data["region"] as String
    val token = data["token"] as String

    val iProov = IProovFlowLauncher()
    iProov.launch(
        applicationContext,
        "wss://$region.rp.secure.iproov.me/ws",
        token,
        iproovOptions,
    )

    val job = CoroutineScope(Dispatchers.Default).launch {
        iProov.sessionsStates.collect { sessionState: IProov.IProovSessionState? ->
            sessionState?.state.let {
                iProovEvents?.emit(sessionState)
                if (it is IProov.IProovState.Success) {
                    validate(userId, token, claimType, extensionId).await()
                    this.cancel()
                }
            }
        }
    }
    job.join()

}

private suspend fun validate(
    userId: String,
    token: String,
    claimType: ClaimType,
    extensionId: String,
): Task<AuthResult> {

    val response = FirebaseFunctions.getInstance()
        .getHttpsCallable("ext-${extensionId}-validate").call(
            mapOf(
                "userId" to userId,
                "token" to token,
                "claimType" to claimType.value,
            )
        ).await()

    val jwt = response.data as String
    return FirebaseAuth.getInstance().signInWithCustomToken(jwt)
}