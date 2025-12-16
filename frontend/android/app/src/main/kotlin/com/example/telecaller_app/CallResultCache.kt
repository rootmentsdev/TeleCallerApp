package com.example.telecaller_app

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

object CallResultCache {
    private const val TAG = "CallResultCache"
    private const val PREFS_NAME = "call_result_cache"
    private const val KEY_PHONE = "phone_"
    private const val KEY_DURATION = "duration_"
    private const val KEY_TIMESTAMP = "timestamp_"
    private const val KEY_CALL_TYPE = "call_type_"

    fun cacheCallResult(
        context: Context,
        phoneNumber: String,
        duration: Int,
        callType: String
    ) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val editor = prefs.edit()

            val key = normalizePhoneNumber(phoneNumber)
            editor.putString(KEY_PHONE + key, phoneNumber)
            editor.putInt(KEY_DURATION + key, duration)
            editor.putLong(KEY_TIMESTAMP + key, System.currentTimeMillis())
            editor.putString(KEY_CALL_TYPE + key, callType)
            editor.apply()

            Log.d(TAG, "Cached call result: $phoneNumber, duration: $duration, type: $callType")
        } catch (e: Exception) {
            Log.e(TAG, "Error caching call result: ${e.message}")
        }
    }

    fun getCachedCallResult(context: Context, phoneNumber: String): Map<String, Any>? {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val key = normalizePhoneNumber(phoneNumber)

            val cachedPhone = prefs.getString(KEY_PHONE + key, null)
            if (cachedPhone != null) {
                val duration = prefs.getInt(KEY_DURATION + key, 0)
                val timestamp = prefs.getLong(KEY_TIMESTAMP + key, 0)
                val callType = prefs.getString(KEY_CALL_TYPE + key, "incoming") ?: "incoming"

                Log.d(TAG, "Retrieved cached call result: $cachedPhone, duration: $duration")

                mapOf(
                    "phoneNumber" to cachedPhone,
                    "duration" to duration,
                    "timestamp" to timestamp,
                    "callType" to callType
                )
            } else {
                Log.d(TAG, "No cached result found for: $phoneNumber")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error retrieving cached call result: ${e.message}")
            null
        }
    }

    fun clearCache(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().clear().apply()
            Log.d(TAG, "Cache cleared")
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing cache: ${e.message}")
        }
    }

    private fun normalizePhoneNumber(phoneNumber: String): String {
        // Extract only digits
        val digits = phoneNumber.replace(Regex("[^0-9]"), "")
        
        // Return last 10 digits
        return if (digits.length >= 10) {
            digits.takeLast(10)
        } else {
            digits
        }
    }
}
