package com.example.personal_learning_os_client

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationManagerCompat

/**
 * Family Insights Notification Listener.
 *
 * STRICT PRIVACY GUARANTEE:
 * This service ONLY reads:
 * 1. Package Name
 * 2. Notification Timestamp
 * 3. Notification Category (e.g., msg, social, promo, call, sys)
 *
 * It NEVER inspects notification title, notification body text, message contents,
 * contact names, images, or any private data.
 */
class FamilyNotificationListenerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val pkgName = sbn.packageName ?: return
        // Ignore our own notifications
        if (pkgName == applicationContext.packageName) return

        val notification = sbn.notification ?: return
        val timestamp = sbn.postTime
        val category = mapCategory(notification.category)

        FamilyInsightsDataQueue.addNotification(
            context = applicationContext,
            packageName = pkgName,
            category = category,
            timestamp = timestamp
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }

    private fun mapCategory(cat: String?): String {
        return when (cat) {
            Notification.CATEGORY_MESSAGE -> "msg"
            Notification.CATEGORY_EMAIL -> "email"
            Notification.CATEGORY_SOCIAL -> "social"
            Notification.CATEGORY_CALL -> "call"
            Notification.CATEGORY_ALARM -> "alarm"
            Notification.CATEGORY_REMINDER -> "reminder"
            Notification.CATEGORY_EVENT -> "event"
            Notification.CATEGORY_PROMO -> "promo"
            Notification.CATEGORY_RECOMMENDATION -> "recommendation"
            Notification.CATEGORY_STATUS -> "status"
            Notification.CATEGORY_SERVICE -> "service"
            Notification.CATEGORY_SYSTEM -> "system"
            Notification.CATEGORY_PROGRESS -> "progress"
            Notification.CATEGORY_NAVIGATION -> "navigation"
            Notification.CATEGORY_TRANSPORT -> "transport"
            Notification.CATEGORY_ERROR -> "error"
            null -> "general"
            else -> cat.lowercase()
        }
    }

    companion object {
        fun isPermissionGranted(context: Context): Boolean {
            val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(context)
            return enabledListeners.contains(context.packageName)
        }
    }
}

