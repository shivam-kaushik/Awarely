package com.example.awarely

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class AlarmScheduler(private val context: Context) {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    
    companion object {
        private const val TAG = "AlarmScheduler"
    }

    fun scheduleExactAlarm(
        id: Int,
        title: String,
        body: String,
        scheduledTimeMillis: Long,
        payload: String?
    ): Boolean {
        try {
            // Check if we can schedule exact alarms
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (!alarmManager.canScheduleExactAlarms()) {
                    Log.e(TAG, "Cannot schedule exact alarms - permission not granted")
                    return false
                }
            }

            // Create intent for AlarmReceiver
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, id)
                putExtra(AlarmReceiver.EXTRA_TITLE, title)
                putExtra(AlarmReceiver.EXTRA_BODY, body)
                putExtra(AlarmReceiver.EXTRA_PAYLOAD, payload)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Schedule exact alarm with wake-up
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    scheduledTimeMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    scheduledTimeMillis,
                    pendingIntent
                )
            }

            Log.d(TAG, "✅ Scheduled exact alarm: id=$id at $scheduledTimeMillis")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to schedule alarm: ${e.message}")
            e.printStackTrace()
            return false
        }
    }

    fun cancelAlarm(id: Int) {
        try {
            // Create intent matching the one used during scheduling
            // The intent must match exactly (same action, component, etc.) for PendingIntent lookup
            val intent = Intent(context, AlarmReceiver::class.java)
            
            // Use FLAG_NO_CREATE to retrieve the existing PendingIntent
            // The request code (id) is the primary matching criterion
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            
            if (pendingIntent != null) {
                // Cancel the alarm
                alarmManager.cancel(pendingIntent)
                // Cancel the PendingIntent itself
                pendingIntent.cancel()
                Log.d(TAG, "✅ Successfully cancelled alarm: id=$id")
            } else {
                // This might happen if alarm already fired or was never scheduled
                Log.w(TAG, "⚠️ No active alarm found to cancel: id=$id (may have already fired or expired)")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to cancel alarm id=$id: ${e.message}", e)
        }
    }

    fun cancelAllAlarms() {
        // Note: There's no direct way to cancel all alarms
        // This would need to be tracked on Flutter side
        Log.d(TAG, "🗑️ Cancel all alarms requested")
    }
}
