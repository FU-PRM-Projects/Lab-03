package com.quanphungg.lab03

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: local_auth needs a FragmentActivity for the
// biometric prompt (S09 lock).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Window flags for S09 (FLAG_SECURE hides the screen in recents and
        // screenshots) and S10 (keep the screen on while breathing).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lab03/window")
            .setMethodCallHandler { call, result ->
                val enabled = call.argument<Boolean>("enabled") ?: false
                val flag = when (call.method) {
                    "setSecure" -> WindowManager.LayoutParams.FLAG_SECURE
                    "setKeepScreenOn" -> WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    else -> {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                }
                if (enabled) window.addFlags(flag) else window.clearFlags(flag)
                result.success(null)
            }
    }
}
