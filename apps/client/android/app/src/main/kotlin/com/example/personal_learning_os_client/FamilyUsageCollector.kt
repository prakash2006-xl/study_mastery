package com.example.personal_learning_os_client

import android.app.AppOpsManager
import android.app.KeyguardManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process

object FamilyUsageCollector {

    fun isUsagePermissionGranted(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun collectUsageData(
        context: Context,
        startTime: Long,
        endTime: Long
    ): Map<String, Any> {
        if (!isUsagePermissionGranted(context)) {
            return mapOf(
                "permission_granted" to false,
                "app_events" to emptyList<Map<String, Any>>(),
                "screen_events" to emptyList<Map<String, Any>>(),
                "app_summaries" to emptyList<Map<String, Any>>()
            )
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf(
                "permission_granted" to true,
                "app_events" to emptyList<Map<String, Any>>(),
                "screen_events" to emptyList<Map<String, Any>>(),
                "app_summaries" to emptyList<Map<String, Any>>()
            )

        val pm = context.packageManager
        val appEvents = mutableListOf<Map<String, Any>>()
        val screenEvents = mutableListOf<Map<String, Any>>()

        // Query raw usage events
        try {
            val events = usageStatsManager.queryEvents(startTime, endTime)
            val event = UsageEvents.Event()

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val eventType = event.eventType
                val ts = event.timeStamp
                val pkg = event.packageName ?: ""

                when (eventType) {
                    UsageEvents.Event.ACTIVITY_RESUMED -> {
                        appEvents.add(
                            mapOf(
                                "package_name" to pkg,
                                "app_name" to getAppLabel(pm, pkg),
                                "event_type" to "MOVE_TO_FOREGROUND",
                                "timestamp" to ts
                            )
                        )
                    }
                    UsageEvents.Event.ACTIVITY_PAUSED,
                    UsageEvents.Event.ACTIVITY_STOPPED -> {
                        appEvents.add(
                            mapOf(
                                "package_name" to pkg,
                                "app_name" to getAppLabel(pm, pkg),
                                "event_type" to "MOVE_TO_BACKGROUND",
                                "timestamp" to ts
                            )
                        )
                    }
                    UsageEvents.Event.SCREEN_INTERACTIVE -> {
                        screenEvents.add(
                            mapOf(
                                "event_type" to "SCREEN_INTERACTIVE",
                                "timestamp" to ts
                            )
                        )
                    }
                    UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                        screenEvents.add(
                            mapOf(
                                "event_type" to "SCREEN_NON_INTERACTIVE",
                                "timestamp" to ts
                            )
                        )
                    }
                    UsageEvents.Event.KEYGUARD_SHOWN -> {
                        screenEvents.add(
                            mapOf(
                                "event_type" to "KEYGUARD_SHOWN",
                                "timestamp" to ts
                            )
                        )
                    }
                    UsageEvents.Event.KEYGUARD_HIDDEN -> {
                        screenEvents.add(
                            mapOf(
                                "event_type" to "KEYGUARD_HIDDEN",
                                "timestamp" to ts
                            )
                        )
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Query aggregated stats for duration and last used
        val appSummaries = mutableListOf<Map<String, Any>>()
        try {
            val statsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_BEST,
                startTime,
                endTime
            )
            val aggregated = mutableMapOf<String, Pair<Long, Long>>() // pkg -> Pair(totalTimeMs, lastTimeUsed)

            for (stats in statsList) {
                if (stats.totalTimeInForeground > 0) {
                    val current = aggregated[stats.packageName]
                    val total = (current?.first ?: 0L) + stats.totalTimeInForeground
                    val last = maxOf(current?.second ?: 0L, stats.lastTimeUsed)
                    aggregated[stats.packageName] = Pair(total, last)
                }
            }

            for ((pkg, pair) in aggregated) {
                appSummaries.add(
                    mapOf(
                        "package_name" to pkg,
                        "app_name" to getAppLabel(pm, pkg),
                        "duration_ms" to pair.first,
                        "last_used_timestamp" to pair.second
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Keyguard current status snapshot
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        val isLocked = keyguardManager?.isKeyguardLocked ?: false

        return mapOf(
            "permission_granted" to true,
            "app_events" to appEvents,
            "screen_events" to screenEvents,
            "app_summaries" to appSummaries,
            "is_keyguard_locked" to isLocked
        )
    }

    private fun getAppLabel(pm: PackageManager, packageName: String): String {
        return try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName.substringAfterLast('.')
        }
    }
}

