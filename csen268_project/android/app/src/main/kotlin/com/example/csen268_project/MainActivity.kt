package com.example.csen268_project

import io.flutter.embedding.android.FlutterActivity
import com.google.firebase.messaging.FirebaseMessaging
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FirebaseMessaging.getInstance().isAutoInitEnabled = true
    }
}
