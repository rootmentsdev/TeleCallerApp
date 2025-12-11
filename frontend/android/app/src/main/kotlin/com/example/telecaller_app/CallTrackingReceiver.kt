package com.example.telecaller_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class CallTrackingReceiver : BroadcastReceiver() {
    companion object {
        private var flutterEngine: FlutterEngine? = null
        private var lastPhoneNumber: String? = null
        private var callAnswerTime: Long = 0
        private var previousState = TelephonyManager.CALL_STATE_IDLE
        private const val TAG = "CallTrackingReceiver"

        fun setFlutterEngine(engine: FlutterEngine) {
            flutterEngine = engine
            Log.d(TAG, "FlutterEngine set for call tracking")
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null) return

        val action = intent.action
        Log.d(TAG, "onReceive called with action: $action")

        when (action) {
            "android.intent.action.PHONE_STATE" -> {
                handlePhoneState(intent)
            }
            "android.intent.action.NEW_OUTGOING_CALL" -> {
                handleOutgoingCall(intent)
            }
        }
    }

    private fun handlePhoneState(intent: Intent) {
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

        Log.d(TAG, "Phone state: $state, Phone: $phoneNumber")

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                lastPhoneNumber = phoneNumber
                previousState = TelephonyManager.CALL_STATE_RINGING
                Log.d(TAG, "Incoming call ringing from: $phoneNumber")
                sendToFlutter("onCallStateChanged", mapOf(
                    "phoneNumber" to (phoneNumber ?: "Unknown"),
                    "state" to "ringing"
                ))
            }
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                if (previousState != TelephonyManager.CALL_STATE_OFFHOOK) {
                    callAnswerTime = System.currentTimeMillis()
                    previousState = TelephonyManager.CALL_STATE_OFFHOOK
                    Log.d(TAG, "Call answered/started")
                    sendToFlutter("onCallStateChanged", mapOf(
                        "phoneNumber" to (phoneNumber ?: lastPhoneNumber ?: "Unknown"),
                        "state" to "answered"
                    ))
                }
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                if (previousState == TelephonyManager.CALL_STATE_OFFHOOK && callAnswerTime > 0) {
                    val duration = ((System.currentTimeMillis() - callAnswerTime) / 1000).toInt()
                    Log.d(TAG, "Call ended. Duration: ${duration}s, Phone: $lastPhoneNumber")
                    sendToFlutter("onCallEnded", mapOf(
                        "phoneNumber" to (lastPhoneNumber ?: "Unknown"),
                        "duration" to duration
                    ))
                }
                lastPhoneNumber = null
                callAnswerTime = 0
                previousState = TelephonyManager.CALL_STATE_IDLE
            }
        }
    }

    private fun handleOutgoingCall(intent: Intent) {
        val phoneNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
        Log.d(TAG, "Outgoing call to: $phoneNumber")
        
        lastPhoneNumber = phoneNumber
        callAnswerTime = System.currentTimeMillis()
        previousState = TelephonyManager.CALL_STATE_OFFHOOK
        
        sendToFlutter("onCallStateChanged", mapOf(
            "phoneNumber" to (phoneNumber ?: "Unknown"),
            "state" to "outgoing"
        ))
    }

    private fun sendToFlutter(method: String, arguments: Map<String, Any>) {
        flutterEngine?.let {
            try {
                val channel = MethodChannel(it.dartExecutor.binaryMessenger, "com.telecaller.app/call_tracking")
                channel.invokeMethod(method, arguments)
                Log.d(TAG, "Sent to Flutter: $method with args: $arguments")
            } catch (e: Exception) {
                Log.e(TAG, "Error sending to Flutter: ${e.message}")
            }
        } ?: run {
            Log.w(TAG, "FlutterEngine not set, cannot send to Flutter")
        }
    }
}
