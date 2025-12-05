package com.example.telecaller_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.util.Log

class PhoneCallService(private val context: Context) {

    private var callStartTime: Long = 0L
    private var eventSink: ((Int) -> Unit)? = null

    fun setEventSink(listener: (Int) -> Unit) {
        eventSink = listener
    }

    fun makeCall(phoneNumber: String) {
        val callIntent = Intent(Intent.ACTION_CALL)
        callIntent.data = Uri.parse("tel:$phoneNumber")
        callIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(callIntent)

        registerCallStateListener()
    }

    private fun registerCallStateListener() {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        telephonyManager.listen(object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)

                when (state) {
                    TelephonyManager.CALL_STATE_OFFHOOK -> {
                        callStartTime = System.currentTimeMillis()
                        Log.d("CALL", "Call Answered.")
                    }

                    TelephonyManager.CALL_STATE_IDLE -> {
                        if (callStartTime > 0) {
                            val durationSeconds =
                                ((System.currentTimeMillis() - callStartTime) / 1000).toInt()
                            Log.d("CALL", "Call Ended. Duration: $durationSeconds")

                            eventSink?.invoke(durationSeconds)
                            callStartTime = 0L
                        }
                    }

                    TelephonyManager.CALL_STATE_RINGING -> {
                        Log.d("CALL", "Phone ringing")
                    }
                }
            }
        }, PhoneStateListener.LISTEN_CALL_STATE)
    }
}