package com.example.heart_rate_app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import com.samsung.android.sdk.healthdata.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.heart_rate_app/heartRate"
    private lateinit var healthDataStore: HealthDataStore
    private var latestHeartRate: Float = 0.0f
    private var latestSpO2: Float = 0.0f
    private var latestStressLevel: Float = 0.0f

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize Samsung Health SDK
        healthDataStore = HealthDataStore(this, object : HealthDataStore.ConnectionListener {
            override fun onConnected() {
                Log.d("SamsungHealth", "Connected to Samsung Health")
            }

            override fun onConnectionFailed(error: HealthConnectionErrorResult?) {
                Log.e("SamsungHealth", "Connection failed: ${error?.errorCode}")
            }

            override fun onDisconnected() {
                Log.e("SamsungHealth", "Disconnected from Samsung Health")
            }
        })
        healthDataStore.connect()
    }

    // Configure Flutter MethodChannel
    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getHeartRate") {
                getHealthData(result)
            }
        }
    }

    // Fetch heart rate, SpO2, and stress level from Samsung Health
    private fun getHealthData(result: MethodChannel.Result) {
        val resolver = HealthDataResolver(healthDataStore, null)
        
        // Create the request for heart rate, SpO2, and stress level data
        val readRequest = HealthDataResolver.ReadRequest.Builder()
            .setDataType(HealthConstants.HeartRate.HEART_RATE)
            .setProperties(arrayOf(HealthConstants.HeartRate.HEART_BEAT_COUNT, HealthConstants.HeartRate.TIME))
            .build()

        val readSpO2Request = HealthDataResolver.ReadRequest.Builder()
            .setDataType(HealthConstants.OxygenSaturation.OXYGEN_SATURATION)
            .setProperties(arrayOf(HealthConstants.OxygenSaturation.OXYGEN_SATURATION, HealthConstants.OxygenSaturation.TIME))
            .build()

        val readStressRequest = HealthDataResolver.ReadRequest.Builder()
            .setDataType(HealthConstants.Stress.STRESS_LEVEL)
            .setProperties(arrayOf(HealthConstants.Stress.STRESS_LEVEL, HealthConstants.Stress.TIME))
            .build()

        // Combine all the requests
        val allRequests = listOf(readRequest, readSpO2Request, readStressRequest)

        // Resolve all health data requests
        resolver.read(*allRequests.toTypedArray()).setResultListener { healthData ->
            if (healthData.count > 0) {
                healthData.iterator().use { iterator ->
                    while (iterator.hasNext()) {
                        val data = iterator.next()
                        
                        // Heart rate
                        if (data.dataType == HealthConstants.HeartRate.HEART_RATE) {
                            latestHeartRate = data.getInt(HealthConstants.HeartRate.HEART_BEAT_COUNT).toFloat()
                            Log.d("SamsungHealth", "Heart Rate: $latestHeartRate BPM")
                        }

                        // SpO2
                        if (data.dataType == HealthConstants.OxygenSaturation.OXYGEN_SATURATION) {
                            latestSpO2 = data.getFloat(HealthConstants.OxygenSaturation.OXYGEN_SATURATION)
                            Log.d("SamsungHealth", "SpO2: $latestSpO2 %")
                        }

                        // Stress Level
                        if (data.dataType == HealthConstants.Stress.STRESS_LEVEL) {
                            latestStressLevel = data.getFloat(HealthConstants.Stress.STRESS_LEVEL)
                            Log.d("SamsungHealth", "Stress Level: $latestStressLevel")
                        }
                    }
                }
                result.success(mapOf(
                    "heartRate" to latestHeartRate.toString(),
                    "spO2" to latestSpO2.toString(),
                    "stressLevel" to latestStressLevel.toString()
                ))
            } else {
                result.error("NO_DATA", "No health data found", null)
            }
        }
    }

    override fun onDestroy() {
        healthDataStore.disconnect()
        super.onDestroy()
    }
}
