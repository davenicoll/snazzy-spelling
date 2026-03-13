package com.davenicoll.snazzy_spelling

import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Ensure hardware volume buttons always control media volume,
        // not ringer/system volume, so TTS volume is adjustable between utterances.
        volumeControlStream = AudioManager.STREAM_MUSIC
    }
}
