package com.example.telecaller_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log

/**
 * Service for making phone calls and integrating with call tracking
 */
class PhoneCallService(private val context: Context) {
    companion object {
        private const val TAG = "PhoneCallService"
        private var eventSinkCallback: ((Map<String, Any>) -> Unit)? = null
    }

    fun setEventSink(callback: (Map<String, Any>) -> Unit) {
        eventSinkCallback = callback
    }

    fun makeCall(phoneNumber: String): Boolean {
        return try {
            Log.d(TAG, "Making call to: $phoneNumber")
            
            // Create intent to make phone call
            val callIntent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$phoneNumber")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            // Start the call
            context.startActivity(callIntent)
            
            // Notify that call was initiated
            eventSinkCallback?.invoke(mapOf(
                "event" to "callInitiated",
                "phoneNumber" to phoneNumber,
                "timestamp" to System.currentTimeMillis()
            ))
            
            Log.d(TAG, "Call initiated successfully to: $phoneNumber")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error making call to $phoneNumber: ${e.message}")
            
            // Notify about call failure
            eventSinkCallback?.invoke(mapOf(
                "event" to "callFailed",
                "phoneNumber" to phoneNumber,
                "error" to (e.message ?: "Unknown error"),
                "timestamp" to System.currentTimeMillis()
            ))
            
            false
        }
    }
}