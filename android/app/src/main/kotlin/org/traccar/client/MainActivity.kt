package org.traccar.client

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.graphics.Rect
import android.util.Rational

class MainActivity: FlutterActivity() {
    // The channel name for platform communication.
    private val CHANNEL = "org.traccar.client/pip"
    // The controller for Picture-in-Picture mode.
    private lateinit var pipController: PipController

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Set up the method channel for platform communication.
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        // Create a PipController instance.
        pipController = PipController(this, channel)

        channel.setMethodCallHandler { call, result ->
            // Check if the method call is for entering PiP mode.
            if (call.method == "enterPipMode") {
                // Enter PiP mode.
                pipController.enterPipMode()
                // Return a success result.
                result.success(null)
            } else {
                // Return a not implemented result for other method calls.
                result.notImplemented()
            }
        }

        // Request to ignore battery optimizations
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.parse("package:" + packageName)
            startActivity(intent)
        }
    }

    override fun onUserLeaveHint() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (this::pipController.isInitialized) {
                pipController.enterPipMode()
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (this::pipController.isInitialized) {
                pipController.onPictureInPictureModeChanged(isInPictureInPictureMode)
            }
        }
    }
}
