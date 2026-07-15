package com.shurokkha.shurokkha

import android.content.ComponentName
import android.content.pm.PackageManager
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayList

class MainActivity : FlutterActivity() {
    private val TRIGGER_CHANNEL = "com.shurokkha/trigger"
    private val DISGUISE_CHANNEL = "com.shurokkha/disguise"
    private var triggerMethodChannel: MethodChannel? = null

    // For tracking volume down clicks
    private val volumeClickTimestamps = ArrayList<Long>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        triggerMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TRIGGER_CHANNEL)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DISGUISE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableDisguise" -> {
                    val success = setLauncherDisguise(true)
                    result.success(success)
                }
                "disableDisguise" -> {
                    val success = setLauncherDisguise(false)
                    result.success(success)
                }
                "isDisguiseEnabled" -> {
                    result.success(isDisguiseActive())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN && event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            val currentTime = System.currentTimeMillis()
            volumeClickTimestamps.add(currentTime)

            // Remove timestamps older than 2 seconds
            val iterator = volumeClickTimestamps.iterator()
            while (iterator.hasNext()) {
                val timestamp = iterator.next()
                if (currentTime - timestamp > 2000) {
                    iterator.remove()
                }
            }

            if (volumeClickTimestamps.size >= 3) {
                volumeClickTimestamps.clear()
                triggerMethodChannel?.invokeMethod("volumeTrigger", null)
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun setLauncherDisguise(enableDisguise: Boolean): Boolean {
        try {
            val pm = packageManager
            val mainActivityAlias = ComponentName(this, "com.shurokkha.shurokkha.MainActivityAlias")
            val calculatorAlias = ComponentName(this, "com.shurokkha.shurokkha.CalculatorAlias")

            if (enableDisguise) {
                // Enable Calculator launcher component, disable original launcher component
                pm.setComponentEnabledSetting(
                    calculatorAlias,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
                )
                pm.setComponentEnabledSetting(
                    mainActivityAlias,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            } else {
                // Enable original launcher component, disable Calculator launcher component
                pm.setComponentEnabledSetting(
                    mainActivityAlias,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
                )
                pm.setComponentEnabledSetting(
                    calculatorAlias,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
            return true
        } catch (e: Exception) {
            return false
        }
    }

    private fun isDisguiseActive(): Boolean {
        try {
            val pm = packageManager
            val calculatorAlias = ComponentName(this, "com.shurokkha.shurokkha.CalculatorAlias")
            val state = pm.getComponentEnabledSetting(calculatorAlias)
            return state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } catch (e: Exception) {
            return false
        }
    }
}
