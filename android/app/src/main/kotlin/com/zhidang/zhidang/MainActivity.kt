package com.zhidang.zhidang

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.zhidang.zhidang/app_icon"
        private val ICON_ALIASES = listOf("default", "classic")
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Older plugin builds may have disabled MainActivity; keep it launchable.
        packageManager.setComponentEnabledSetting(
            ComponentName(this, MainActivity::class.java),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supportsAlternateIcons" -> result.success(true)
                    "getAlternateIconName" -> result.success(currentIconAlias())
                    "setAlternateIconName" -> {
                        val iconName = call.argument<String>("iconName") ?: "default"
                        try {
                            setIconAlias(iconName)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ICON_CHANGE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun currentIconAlias(): String {
        val pm = packageManager
        for (alias in ICON_ALIASES) {
            val component = ComponentName(this, "$packageName.$alias")
            val state = pm.getComponentEnabledSetting(component)
            val enabled = when (state) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
                PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> alias == "default"
                else -> false
            }
            if (enabled) return alias
        }
        return "default"
    }

    private fun setIconAlias(iconName: String) {
        val target = if (ICON_ALIASES.contains(iconName)) iconName else "default"
        val pm = packageManager

        // Target activity must stay enabled; older plugin builds may have disabled it.
        pm.setComponentEnabledSetting(
            ComponentName(this, MainActivity::class.java),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )

        // Enable target first so the launcher never loses all icons.
        val ordered = listOf(target) + ICON_ALIASES.filter { it != target }
        for (alias in ordered) {
            val component = ComponentName(this, "$packageName.$alias")
            val newState = if (alias == target) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            pm.setComponentEnabledSetting(
                component,
                newState,
                PackageManager.DONT_KILL_APP,
            )
        }
    }
}
