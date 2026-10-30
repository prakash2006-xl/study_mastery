package com.example.personal_learning_os_client

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.os.Build

object FamilyNetworkCollector {

    fun collectNetworkStats(
        context: Context,
        startTime: Long,
        endTime: Long
    ): Map<String, Any> {
        val networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as? NetworkStatsManager
            ?: return emptyMap()

        var wifiRx = 0L
        var wifiTx = 0L
        var mobileRx = 0L
        var mobileTx = 0L

        // Overall device totals
        try {
            val wifiBucket = networkStatsManager.querySummaryForDevice(
                ConnectivityManager.TYPE_WIFI,
                "",
                startTime,
                endTime
            )
            wifiRx = wifiBucket.rxBytes
            wifiTx = wifiBucket.txBytes
        } catch (e: Exception) {
            // Permission or device not supported
        }

        try {
            val mobileBucket = networkStatsManager.querySummaryForDevice(
                ConnectivityManager.TYPE_MOBILE,
                null,
                startTime,
                endTime
            )
            mobileRx = mobileBucket.rxBytes
            mobileTx = mobileBucket.txBytes
        } catch (e: Exception) {
            // Permission or device not supported
        }

        // Per-app network breakdown where supported
        val appBreakdown = mutableListOf<Map<String, Any>>()
        val pm = context.packageManager

        fun collectForType(networkType: Int, typeName: String) {
            try {
                val stats = networkStatsManager.querySummary(networkType, null, startTime, endTime)
                val bucket = NetworkStats.Bucket()
                val uidTotals = mutableMapOf<Int, Pair<Long, Long>>() // uid -> (rx, tx)

                while (stats.hasNextBucket()) {
                    stats.getNextBucket(bucket)
                    val uid = bucket.uid
                    if (uid > 0) {
                        val current = uidTotals[uid] ?: Pair(0L, 0L)
                        uidTotals[uid] = Pair(current.first + bucket.rxBytes, current.second + bucket.txBytes)
                    }
                }
                stats.close()

                for ((uid, pair) in uidTotals) {
                    if (pair.first > 0 || pair.second > 0) {
                        val packages = pm.getPackagesForUid(uid)
                        val pkg = packages?.firstOrNull() ?: "uid_$uid"
                        val label = try {
                            val appInfo = pm.getApplicationInfo(pkg, 0)
                            pm.getApplicationLabel(appInfo).toString()
                        } catch (e: Exception) {
                            pkg.substringAfterLast('.')
                        }

                        appBreakdown.add(
                            mapOf(
                                "package_name" to pkg,
                                "app_name" to label,
                                "network_type" to typeName,
                                "rx_bytes" to pair.first,
                                "tx_bytes" to pair.second,
                                "start_time" to startTime,
                                "end_time" to endTime
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                // Ignore per-uid if restricted
            }
        }

        collectForType(ConnectivityManager.TYPE_WIFI, "WIFI")
        collectForType(ConnectivityManager.TYPE_MOBILE, "MOBILE")

        return mapOf(
            "wifi_rx" to wifiRx,
            "wifi_tx" to wifiTx,
            "mobile_rx" to mobileRx,
            "mobile_tx" to mobileTx,
            "start_time" to startTime,
            "end_time" to endTime,
            "timestamp" to System.currentTimeMillis(),
            "app_breakdown" to appBreakdown
        )
    }
}

