package org.traccar.client

import android.app.PictureInPictureParams
import android.content.Context
import android.os.Build
import android.util.Rational
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel

class PipController(private val context: Context, private val channel: MethodChannel) {

    /**
     * Enters Picture-in-Picture mode.
     */
    @RequiresApi(Build.VERSION_CODES.O)
    fun enterPipMode() {
        (context as? MainActivity)?.let { activity ->
            // Create a Rational for the aspect ratio of the PiP window.
            val aspectRatio = Rational(16, 9)

            // Create PictureInPictureParams to configure the PiP window.
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(aspectRatio)
                .build()

            // Enter Picture-in-Picture mode.
            activity.enterPictureInPictureMode(params)
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        PipStatus.sendPipStatus(isInPictureInPictureMode)
    }
}