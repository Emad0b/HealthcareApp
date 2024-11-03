package com.example.heart_rate_app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.heart_rate_app/heartRate"
    private lateinit var sensorManager: SensorManager
    private var heartRateSensor: Sensor? = null
    private var heartRate: Float = 0.0f

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        heartRateSensor = sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)

        // Set up the heart rate sensor listener
        val heartRateListener = object : SensorEventListener {
            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

            override fun onSensorChanged(event: SensorEvent?) {
                if (event != null) {
                    heartRate = event.values[0]
                }
            }
        }

        heartRateSensor?.let {
            sensorManager.registerListener(heartRateListener, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    // Configure MethodChannel in configureFlutterEngine, where the Flutter engine is ready
    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getHeartRate") {
                result.success(heartRate.toString())
            }
        }
    }
}
