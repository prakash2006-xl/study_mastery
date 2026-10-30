package com.example.personal_learning_os_client

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

/**
 * Periodic WorkManager worker for Family Insights.
 * - Respects Android battery restrictions (requires battery not low).
 * - Avoids continuous background polling / foreground service drains.
 * - Detects revoked permissions safely.
 * - Stores pending events in FamilyInsightsDataQueue for local Flutter SQLite sync.
 */
class FamilyInsightsWorker(
    private val context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        if (FamilyInsightsDataQueue.isMonitoringPaused(context)) {
            return Result.success()
        }

        try {
            val now = System.currentTimeMillis()
            // Look back over the past 15 minutes
            val startTime = now - (15 * 60 * 1000)

            // 1. Battery snapshot
            val batterySnapshot = FamilyBatteryCollector.collectBatterySnapshot(context)
            FamilyInsightsDataQueue.addBackgroundEvent(context, "battery", batterySnapshot)

            // 2. Usage stats (if permission is still granted)
            if (FamilyUsageCollector.isUsagePermissionGranted(context)) {
                val usageData = FamilyUsageCollector.collectUsageData(context, startTime, now)
                FamilyInsightsDataQueue.addBackgroundEvent(context, "usage", usageData)
            }

            // 3. Network snapshot
            val networkStats = FamilyNetworkCollector.collectNetworkStats(context, startTime, now)
            if (networkStats.isNotEmpty()) {
                FamilyInsightsDataQueue.addBackgroundEvent(context, "network", networkStats)
            }

            // 4. Optional location (only if opted-in and permitted)
            val location = FamilyLocationCollector.collectLocationSnapshot(context)
            if (location != null) {
                FamilyInsightsDataQueue.addBackgroundEvent(context, "location", location)
            }

            return Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            return Result.retry()
        }
    }

    companion object {
        const val WORK_TAG = "family_insights_periodic_worker"
        const val UNIQUE_WORK_NAME = "FamilyInsightsPeriodicWork"
    }
}

