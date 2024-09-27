package com.iproov.firebase

import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class PrivacyPolicyActivity : AppCompatActivity() {
    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_privacy_policy)

        webView = findViewById(R.id.webView)
        webView.settings.javaScriptEnabled = true  // Enable JavaScript (if needed)
        webView.settings.domStorageEnabled = true  // Enable DOM storage

        // Use WebViewClient to ensure WebView opens content inside the app
        webView.webViewClient = WebViewClient()

        // Load your content
        webView.loadUrl("https://www.example.com")
    }

    override fun onPause() {
        super.onPause()
        webView.onPause()
    }

    override fun onResume() {
        super.onResume()
        webView.onResume()
    }

    override fun onDestroy() {
        webView.destroy()
        super.onDestroy()
    }
}