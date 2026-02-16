package com.example.app_chat_hospital

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app_chat_hospital/recent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setRecentColor") {
                val colorHex = call.argument<String>("color")
                if (colorHex != null) {
                    setRecentAppColor(colorHex)
                    result.success(null)
                } else {
                    result.error("INVALID", "Color is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setRecentAppColor(colorHex: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                val window = window
                val colorInt = android.graphics.Color.parseColor(colorHex)
                window.statusBarColor = colorInt
                window.navigationBarColor = colorInt
                // Có thể thêm code để set màu recent apps nếu thiết bị hỗ trợ
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
