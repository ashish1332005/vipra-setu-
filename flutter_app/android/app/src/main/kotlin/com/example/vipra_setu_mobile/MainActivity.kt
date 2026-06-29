package com.viprasetu.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.speech.RecognizerIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val channelName = "vipra_setu/speech"
    private val speechRequestCode = 2411
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "listen") {
                    startSpeech(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun startSpeech(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Voice search is already listening.", null)
            return
        }
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak service name")
        }
        pendingResult = result
        try {
            startActivityForResult(intent, speechRequestCode)
        } catch (error: ActivityNotFoundException) {
            pendingResult = null
            result.error("unavailable", "Speech recognition is not available.", null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != speechRequestCode) return

        val result = pendingResult ?: return
        pendingResult = null
        if (resultCode == Activity.RESULT_OK) {
            val matches = data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            result.success(matches?.firstOrNull().orEmpty())
        } else {
            result.success("")
        }
    }
}
