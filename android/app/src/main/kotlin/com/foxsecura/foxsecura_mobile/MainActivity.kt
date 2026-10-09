// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

package com.foxsecura.foxsecura_mobile

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "foxsecura/device")
            .setMethodCallHandler { call, result ->
                if (call.method != "audit") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val findings = mutableListOf<Map<String, String>>()
                    fun add(title: String, details: String, severity: String) {
                        findings.add(mapOf("title" to title, "details" to details, "severity" to severity))
                    }
                    val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                    if (!keyguard.isDeviceSecure) {
                        add("Verrouillage absent", "Configure un code de verrouillage sécurisé.", "warning")
                    } else {
                        add("Verrouillage configuré", "Un verrouillage sécurisé est configuré.", "info")
                    }
                    val adb = Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0)
                    if (adb == 1) {
                        add("Débogage USB activé", "Désactive ADB lorsque tu ne l’utilises pas.", "warning")
                    } else {
                        add("Débogage USB désactivé", "ADB n’est pas activé.", "info")
                    }
                    val developer = Settings.Global.getInt(contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0)
                    if (developer == 1) add("Options développeur activées", "Vérifie tes réglages avancés.", "info")
                    val patch = Build.VERSION.SECURITY_PATCH
                    add("Correctif Android", if (patch.isNullOrBlank()) "Date inconnue." else "Correctif déclaré : $patch.", "info")
                    result.success(mapOf("platform" to "Android ${Build.VERSION.RELEASE}", "findings" to findings))
                } catch (e: Exception) {
                    result.error("AUDIT_FAILED", e.message, null)
                }
            }
    }
}
