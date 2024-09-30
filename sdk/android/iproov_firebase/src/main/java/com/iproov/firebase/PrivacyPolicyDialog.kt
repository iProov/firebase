package com.iproov.firebase

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.fragment.app.DialogFragment

class PrivacyPolicyDialog : DialogFragment() {
    private lateinit var webView: WebView

    private var listener: ResultListener? = null

    interface ResultListener {
        fun onAccept()
        fun onDecline()
    }
    companion object {
        private const val ARG_URL = "arg_url"

        fun newInstance(url: String): PrivacyPolicyDialog {
            val fragment = PrivacyPolicyDialog()
            val args = Bundle()
            args.putString(ARG_URL, url)
            fragment.arguments = args
            return fragment
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.dialog_privacy_policy, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        webView = view.findViewById(R.id.webView)
    }

    override fun onStart() {
        super.onStart()

        val url = arguments?.getString(ARG_URL) ?: throw IllegalArgumentException("URL not provided")

        dialog?.let {
            val width = ViewGroup.LayoutParams.MATCH_PARENT
            val height = ViewGroup.LayoutParams.MATCH_PARENT
            it.window?.setLayout(width, height)
            it.window?.setBackgroundDrawableResource(android.R.color.transparent)
        }

        with(webView) {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true

            webViewClient = object : WebViewClient() {

                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    request?.url?.toString()?.let {
                        if (it.startsWith("sdk://consent/accept")) {
                            listener?.onAccept()
                            dismiss()
                            return true
                        } else if (it.startsWith("sdk://consent/decline")) {
                            listener?.onDecline()
                            dismiss()
                            return true
                        }
                    }
                    return super.shouldOverrideUrlLoading(view, request)
                }
            }

            loadUrl(url)
        }

    }

    fun setOnDialogResultListener(listener: ResultListener) {
        this.listener = listener
    }

    override fun onDetach() {
        super.onDetach()
        listener = null
    }

    override fun onDestroy() {
        webView.destroy()
        super.onDestroy()
    }

}