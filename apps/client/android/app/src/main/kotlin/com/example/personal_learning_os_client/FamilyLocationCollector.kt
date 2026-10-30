package com.example.personal_learning_os_client

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import androidx.core.content.ContextCompat

object FamilyLocationCollector {

    fun isPermissionGranted(context: Context): Boolean {
        val fineGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val coarseGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        return fineGranted || coarseGranted
    }

    /**
     * Collects the last known location ONLY when explicitly enabled by user
     * and permission is granted.
     * Strictly avoids covert tracking.
     */
    fun collectLocationSnapshot(context: Context): Map<String, Any>? {
        if (!FamilyInsightsDataQueue.isLocationMonitoringEnabled(context)) {
            return null
        }

        if (!isPermissionGranted(context)) {
            return null
        }

        val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return null

        var bestLocation: Location? = null

        try {
            val providers = lm.getProviders(true)
            for (provider in providers) {
                val l = lm.getLastKnownLocation(provider) ?: continue
                if (bestLocation == null || l.accuracy < bestLocation.accuracy) {
                    bestLocation = l
                }
            }
        } catch (e: SecurityException) {
            return null
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }

        val loc = bestLocation ?: return null
        return mapOf(
            "latitude" to loc.latitude,
            "longitude" to loc.longitude,
            "accuracy" to loc.accuracy.toDouble(),
            "timestamp" to loc.time
        )
    }
}

