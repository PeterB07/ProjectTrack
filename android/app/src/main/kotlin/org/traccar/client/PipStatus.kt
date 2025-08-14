package org.traccar.client

import io.flutter.plugin.common.MethodChannel

object PipStatus {
    private var channel: MethodChannel? = null

    fun setMethodChannel(methodChannel: MethodChannel) {
        channel = methodChannel
    }

    fun sendPipStatus(isInPictureInPictureMode: Boolean) {
        channel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }
}