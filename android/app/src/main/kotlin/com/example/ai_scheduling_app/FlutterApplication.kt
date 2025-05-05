package com.example.ai_scheduling_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

class FlutterApplication : android.app.Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Pre-warm the Flutter engine
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        
        // Cache the Flutter engine to be used by FlutterActivity
        FlutterEngineCache.getInstance().put("my_engine_id", flutterEngine)
        
        // Register all plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}