package com.example.personal_learning_os_client

import android.Manifest
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.personal_learning_os_client/family_insights"
    private val LOCATION_REQ_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPermissionsStatus" -> {
                    val status = mapOf(
                        "usage_stats" to FamilyUsageCollector.isUsagePermissionGranted(context),
                        "notification_listener" to FamilyNotificationListenerService.isPermissionGranted(context),
                        "battery" to true,
                        "network_stats" to true,
                        "location" to FamilyLocationCollector.isPermissionGranted(context),
                        "location_enabled" to FamilyInsightsDataQueue.isLocationMonitoringEnabled(context),
                        "monitoring_paused" to FamilyInsightsDataQueue.isMonitoringPaused(context)
                    )
                    result.success(status)
                }

                "openPermissionSettings" -> {
                    val type = call.argument<String>("type") ?: ""
                    try {
                        when (type) {
                            "usage_stats" -> {
                                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                                startActivity(intent)
                                result.success(true)
                            }
                            "notification_listener" -> {
                                val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                                startActivity(intent)
                                result.success(true)
                            }
                            "location" -> {
                                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                    data = Uri.fromParts("package", packageName, null)
                                }
                                startActivity(intent)
                                result.success(true)
                            }
                            else -> {
                                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                    data = Uri.fromParts("package", packageName, null)
                                }
                                startActivity(intent)
                                result.success(true)
                            }
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.error("INTENT_ERROR", e.localizedMessage, null)
                    }
                }

                "requestLocationPermission" -> {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        ),
                        LOCATION_REQ_CODE
                    )
                    result.success(true)
                }

                "collectAppUsage" -> {
                    val start = call.argument<Number>("startTime")?.toLong() ?: (System.currentTimeMillis() - 86400000L)
                    val end = call.argument<Number>("endTime")?.toLong() ?: System.currentTimeMillis()
                    val data = FamilyUsageCollector.collectUsageData(context, start, end)
                    result.success(data)
                }

                "collectBatteryStatus" -> {
                    val data = FamilyBatteryCollector.collectBatterySnapshot(context)
                    result.success(data)
                }

                "collectNetworkStats" -> {
                    val start = call.argument<Number>("startTime")?.toLong() ?: (System.currentTimeMillis() - 86400000L)
                    val end = call.argument<Number>("endTime")?.toLong() ?: System.currentTimeMillis()
                    val data = FamilyNetworkCollector.collectNetworkStats(context, start, end)
                    result.success(data)
                }

                "getNotificationEvents" -> {
                    val notifications = FamilyInsightsDataQueue.getAndClearNotifications(context)
                    result.success(notifications)
                }

                "collectLocation" -> {
                    val location = FamilyLocationCollector.collectLocationSnapshot(context)
                    result.success(location)
                }

                "getDeviceInfo" -> {
                    val deviceId = try {
                        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: "android_${Build.ID}"
                    } catch (e: Exception) {
                        "android_${Build.ID}"
                    }
                    val info = mapOf(
                        "device_id" to deviceId,
                        "device_model" to "${Build.MANUFACTURER} ${Build.MODEL}",
                        "os_version" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
                    )
                    result.success(info)
                }

                "scheduleBackgroundWork" -> {
                    val intervalMinutes = (call.argument<Number>("intervalMinutes")?.toLong() ?: 15L).coerceAtLeast(15L)
                    try {
                        val constraints = Constraints.Builder()
                            .setRequiresBatteryNotLow(true)
                            .build()

                        val workRequest = PeriodicWorkRequestBuilder<FamilyInsightsWorker>(
                            intervalMinutes,
                            TimeUnit.MINUTES
                        )
                            .setConstraints(constraints)
                            .addTag(FamilyInsightsWorker.WORK_TAG)
                            .build()

                        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                            FamilyInsightsWorker.UNIQUE_WORK_NAME,
                            ExistingPeriodicWorkPolicy.UPDATE,
                            workRequest
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.error("WORK_ERROR", e.localizedMessage, null)
                    }
                }

                "cancelBackgroundWork" -> {
                    try {
                        WorkManager.getInstance(context).cancelUniqueWork(FamilyInsightsWorker.UNIQUE_WORK_NAME)
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.error("WORK_CANCEL_ERROR", e.localizedMessage, null)
                    }
                }

                "getPendingBackgroundEvents" -> {
                    val events = FamilyInsightsDataQueue.getAndClearBackgroundEvents(context)
                    result.success(events)
                }

                "setMonitoringPaused" -> {
                    val paused = call.argument<Boolean>("paused") ?: false
                    FamilyInsightsDataQueue.setMonitoringPaused(context, paused)
                    result.success(true)
                }

                "setLocationMonitoringEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    FamilyInsightsDataQueue.setLocationMonitoringEnabled(context, enabled)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}
