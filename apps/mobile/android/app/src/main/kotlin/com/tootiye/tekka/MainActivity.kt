package com.tootiye.tekka

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Android 15 (SDK 35) draws apps edge-to-edge by default. Opting in
    // explicitly via WindowCompat also stops the platform from invoking the
    // deprecated setStatusBarColor / setNavigationBarColor APIs that the
    // Play Console flags on the production release. WindowCompat is preferred
    // over androidx.activity.enableEdgeToEdge here because FlutterActivity
    // doesn't satisfy that extension's receiver type at compile time.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
