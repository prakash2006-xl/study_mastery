package com.example.personal_learning_os_client

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object FamilyInsightsDataQueue {
    private const val PREFS_NAME = "family_insights_queue"
    private const val KEY_NOTIFICATIONS = "pending_notifications"
    private const val KEY_BACKGROUND_EVENTS = "pending_background_events"
    private const val KEY_MONITORING_PAUSED = "monitoring_paused"
    private const val KEY_LOCATION_ENABLED = "location_monitoring_enabled"

    private val lock = Any()

    fun isMonitoringPaused(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_MONITORING_PAUSED, false)
    }

    fun setMonitoringPaused(context: Context, paused: Boolean) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_MONITORING_PAUSED, paused).apply()
    }

    fun isLocationMonitoringEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_LOCATION_ENABLED, false)
    }

    fun setLocationMonitoringEnabled(context: Context, enabled: Boolean) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_LOCATION_ENABLED, enabled).apply()
    }

    fun addNotification(context: Context, packageName: String, category: String, timestamp: Long) {
        synchronized(lock) {
            if (isMonitoringPaused(context)) return

            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existingJson = prefs.getString(KEY_NOTIFICATIONS, "[]") ?: "[]"
            val array = try {
                JSONArray(existingJson)
            } catch (e: Exception) {
                JSONArray()
            }

            // Cap the queue at 500 items to respect storage limits
            if (array.length() > 500) {
                array.remove(0)
            }

            val item = JSONObject().apply {
                put("package_name", packageName)
                put("category", category)
                put("timestamp", timestamp)
            }
            array.put(item)
            prefs.edit().putString(KEY_NOTIFICATIONS, array.toString()).apply()
        }
    }

    fun getAndClearNotifications(context: Context): List<Map<String, Any>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString(KEY_NOTIFICATIONS, "[]") ?: "[]"
            val result = mutableListOf<Map<String, Any>>()
            try {
                val array = JSONArray(jsonString)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    result.add(
                        mapOf(
                            "package_name" to obj.optString("package_name", ""),
                            "category" to obj.optString("category", "other"),
                            "timestamp" to obj.optLong("timestamp", System.currentTimeMillis())
                        )
                    )
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            prefs.edit().remove(KEY_NOTIFICATIONS).apply()
            return result
        }
    }

    fun addBackgroundEvent(context: Context, eventType: String, data: Map<String, Any>) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existingJson = prefs.getString(KEY_BACKGROUND_EVENTS, "[]") ?: "[]"
            val array = try {
                JSONArray(existingJson)
            } catch (e: Exception) {
                JSONArray()
            }

            if (array.length() > 200) {
                array.remove(0)
            }

            val item = JSONObject().apply {
                put("event_type", eventType)
                put("timestamp", System.currentTimeMillis())
                put("data", JSONObject(data))
            }
            array.put(item)
            prefs.edit().putString(KEY_BACKGROUND_EVENTS, array.toString()).apply()
        }
    }

    fun getAndClearBackgroundEvents(context: Context): List<Map<String, Any>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString(KEY_BACKGROUND_EVENTS, "[]") ?: "[]"
            val result = mutableListOf<Map<String, Any>>()
            try {
                val array = JSONArray(jsonString)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val dataObj = obj.optJSONObject("data")
                    val dataMap = mutableMapOf<String, Any>()
                    if (dataObj != null) {
                        val keys = dataObj.keys()
                        while (keys.hasNext()) {
                            val key = keys.next()
                            dataMap[key] = dataObj.get(key)
                        }
                    }
                    result.add(
                        mapOf(
                            "event_type" to obj.optString("event_type", ""),
                            "timestamp" to obj.optLong("timestamp", System.currentTimeMillis()),
                            "data" to dataMap
                        )
                    )
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            prefs.edit().remove(KEY_BACKGROUND_EVENTS).apply()
            return result
        }
    }
}

