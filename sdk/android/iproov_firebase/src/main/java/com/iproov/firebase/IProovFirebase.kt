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
    GENUINE_PRESENCE("genuine_presence")
}

enum class ClaimType(val value: String) {
    ENROL("enrol"),
    VERIFY("verify"),
}

fun FirebaseAuth.iProov(region: String? = null, extensionId: String? = null) =
    IProovFirebaseAuth(this, extensionId = extensionId ?: defaultExtensionId, region = region)

class IProovFirebaseAuth(
    private val functions: FirebaseFunctions,
    private val auth: FirebaseAuth,
    private val extensionId: String
) {

    constructor(
        auth: FirebaseAuth,
        extensionId: String? = null,
        region: String? = null
    ) : this(
        FirebaseFunctions.getInstance(auth.app, region ?: defaultRegion),
        auth,
        extensionId = extensionId ?: defaultExtensionId
    )

    suspend fun createUser(
        applicationContext: Context,
        userId: String,
        iProovEvents: MutableStateFlow<IProov.IProovSessionState?>? = null,
        assuranceType: AssuranceType = AssuranceType.GENUINE_PRESENCE,
        iproovOptions: IProov.Options = IProov.Options(),
    ) {
        return doIProov(
            applicationContext,
            userId,
            iProovEvents,
            assuranceType,
            ClaimType.ENROL,
            iproovOptions,
        )
    }

    suspend fun signIn(
        applicationContext: Context,
        userId: String,
        iProovEvents: MutableStateFlow<IProov.IProovSessionState?>? = null,
        assuranceType: AssuranceType = AssuranceType.GENUINE_PRESENCE,
        iProovOptions: IProov.Options = IProov.Options(),
    ) {
        return doIProov(
            applicationContext,
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

    private suspend fun doIProov(
        applicationContext: Context,
        userId: String,
        iProovEvents: MutableStateFlow<IProov.IProovSessionState?>?,
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

        val iProov = IProovFlowLauncher()
        iProov.launch(
            applicationContext,
            "wss://$region.rp.secure.iproov.me/ws",
            token,
            iproovOptions
        )

        val job =
            CoroutineScope(Dispatchers.Default).launch {
                iProov.sessionsStates.collect { sessionState: IProov.IProovSessionState? ->
                    sessionState?.state.let {
                        iProovEvents?.emit(sessionState)
                        if (it is IProov.IProovState.Success) {
                            validate(userId, token, claimType).await()
                            this.cancel()
                        }
                    }
                }
            }
        job.join()
    }

    companion object {
        private const val defaultExtensionId = "auth-iproov"
        private const val defaultRegion = "us-central1"
    }
}
