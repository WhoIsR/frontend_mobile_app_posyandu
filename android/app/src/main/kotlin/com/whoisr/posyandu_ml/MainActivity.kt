package com.whoisr.posyandu_ml

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            "posyandu_alerts",
            "Peringatan Posyandu",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Notifikasi penting untuk rujukan, validasi, dan tindak lanjut Posyandu"
            enableVibration(true)
        }

        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
