package com.example.ai_scheduling_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    // You can override getCachedEngineId() to use the pre-warmed engine
    // or remove this if you want the default engine creation behavior
    override fun getCachedEngineId(): String? {
        return "my_engine_id"
    }
}
