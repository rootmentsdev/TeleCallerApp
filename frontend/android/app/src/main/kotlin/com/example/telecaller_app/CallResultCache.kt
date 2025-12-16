package com.example.telecaller_app

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

/**
 * Manages call result caching using SharedPreferences
 * Ensures call duration data persists even when app is backgrounded during calls
 */
object CallResultCache {
    private const val PREFS_NAME = "call_results_cache"
    private const val KEY_LATEST_PHONE = "latest_phone_number"
    private const val KEY_LATEST_DURATION = "latest_duration"
    private const val KEY_LATEST_TIMESTAMP = "latest_timestamp"
    private const val KEY_LATEST_TYPE = "latest_call_type"
    private const val TAG = "CallResultCache"

    /**
     * Cache call result when call ends
     */
    fun cacheCallResult(
        context: Context,
        phoneNumber: String,
        duration: Int,
        callType: String = "outgoing"
    ) {
        try {
            val prefs = getPrefs(context)
            val timestamp = System.currentTimeMillis()
            
            prefs.edit().apply {
                putString(KEY_LATEST_PHONE, phoneNumber)
                putInt(KEY_LATEST_DURATION, duration)
                putLong(KEY_LATEST_TIMESTAMP, timestamp)
                putString(KEY_LATEST_TYPE, callType)
                apply()
            }
            
            Log.d(TAG, "Cached call result: $phoneNumber, duration: ${duration}s, type: $callType")
        } catch (e: Exception) {
            Log.e(TAG, "Error caching call result: ${e.message}")
        }
    }

    /**
     * Get latest cached call result
     */
    fun getLatestCallResult(context: Context): Map<String, Any?> {
        return try {
            val prefs = getPrefs(context)
            val phoneNumber = prefs.getString(KEY_LATEST_PHONE, null)
            val duration = prefs.getInt(KEY_LATEST_DURATION, -1)
            val timestamp = prefs.getLong(KEY_LATEST_TIMESTAMP, 0)
            val callType = prefs.getString(KEY_LATEST_TYPE, "unknown")
            
            if (phoneNumber != null && duration >= 0 && timestamp > 0) {
                Log.d(TAG, "Retrieved cached call result: $phoneNumber, duration: ${duration}s")
                mapOf(
                    "phoneNumber" to phoneNumber,
                    "duration" to duration,
                    "timestamp" to timestamp,
                    "callType" to callType
                )
            } else {
                Log.d(TAG, "No valid cached call result found")
                emptyMap<String, Any?>()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error retrieving cached call result: ${e.message}")
            emptyMap()
        }
    }

    /**
     * Clear cached call result for specific phone number
     */
    fun clearCallResult(context: Context, phoneNumber: String?) {
        try {
            val prefs = getPrefs(context)
            val cachedPhone = prefs.getString(KEY_LATEST_PHONE, null)
            
            // Only clear if phone numbers match or if phoneNumber is null (clear all)
            if (phoneNumber == null || cachedPhone == phoneNumber) {
                prefs.edit().apply {
                    remove(KEY_LATEST_PHONE)
                    remove(KEY_LATEST_DURATION)
                    remove(KEY_LATEST_TIMESTAMP)
                    remove(KEY_LATEST_TYPE)
                    apply()
                }
                Log.d(TAG, "Cleared cached call result for: $phoneNumber")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing cached call result: ${e.message}")
        }
    }

    /**
     * Check if cached result is for specific phone number and within time limit
     */
    fun isValidCachedResult(
        context: Context, 
        phoneNumber: String, 
        maxAgeMinutes: Int = 5
    ): Boolean {
        return try {
            val result = getLatestCallResult(context)
            val cachedPhone = result["phoneNumber"] as? String
            val timestamp = result["timestamp"] as? Long ?: 0
            val currentTime = System.currentTimeMillis()
            val ageMinutes = (currentTime - timestamp) / (1000 * 60)
            
            cachedPhone == phoneNumber && ageMinutes <= maxAgeMinutes
        } catch (e: Exception) {
            Log.e(TAG, "Error checking cached result validity: ${e.message}")
            false
        }
    }

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
}