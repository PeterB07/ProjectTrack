import Foundation
import AVKit
import Flutter

class PipController {
    // The Flutter plugin registrar.
    private let registrar: FlutterPluginRegistrar
    // The Picture-in-Picture controller.
    private var pipController: AVPictureInPictureController?
    // A flag to indicate if PiP is possible.
    private var pipPossible: Bool = false

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    /// Sets up the Picture-in-Picture mode.
    func setupPip() {
        // Set the audio session category to playback.
        if #available(iOS 9.0, *) {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playback, mode: .moviePlayback)
            } catch {
                print("Setting category to AVAudioSessionCategoryPlayback failed.")
            }
        }

        // Create a AVPictureInPictureController instance.
        let factory = registrar.lookupKey(forAsset: "assets/pip_view.swift")
        pipController = AVPictureInPictureController(contentSource: .init(
            sampleBufferDisplayLayer: .init(),
            playbackDelegate: self
        ))

        // Enable automatic PiP from inline playback.
        if #available(iOS 14.2, *) {
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
    }

    /// Enters Picture-in-Picture mode.
    func enterPipMode() {
        // If PiP is possible, start PiP mode.
        if pipPossible {
            pipController?.startPictureInPicture()
        }
    }
}

extension PipController: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
    }

    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
    }

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }