package com.trackora.cafebazaar

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import com.farsitel.bazaar.referrerprovider.ReferrerProviderService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class TrackoraCafeBazaarPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        const val BAZAAR_PACKAGE = "com.farsitel.bazaar"
        const val SERVICE_NAME = "com.farsitel.bazaar.referrerprovider.ReferrerProviderServiceImpl"
        const val SERVICE_ACTION = "com.cafebazaar.referrer.BIND"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.trackora/cafebazaar")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isAvailable" -> checkAvailability(result)
            "fetchReferrer" -> fetchReferrer(result)
            else -> result.notImplemented()
        }
    }

    private fun checkAvailability(result: Result) {
        try {
            val intent = Intent(SERVICE_ACTION).apply {
                component = ComponentName(BAZAAR_PACKAGE, SERVICE_NAME)
            }
            val resolved = context.packageManager.queryIntentServices(intent, 0)
            result.success(resolved.isNotEmpty())
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun fetchReferrer(result: Result) {
        val intent = Intent(SERVICE_ACTION).apply {
            component = ComponentName(BAZAAR_PACKAGE, SERVICE_NAME)
        }

        val resolved = context.packageManager.queryIntentServices(intent, 0)
        if (resolved.isEmpty()) {
            val map = HashMap<String, Any?>()
            map["status"] = "service_unavailable"
            map["message"] = "CafeBazaar is not installed or referrer service is unavailable."
            result.success(map)
            return
        }

        var isCompleted = false
        val mainHandler = Handler(Looper.getMainLooper())

        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                if (isCompleted) return
                isCompleted = true

                try {
                    val service = ReferrerProviderService.Stub.asInterface(binder)
                    val bundle = service.getReferrer(context.packageName)

                    if (bundle == null) {
                        val map = HashMap<String, Any?>()
                        map["status"] = "not_found"
                        map["message"] = "No referrer data found for package in CafeBazaar"
                        mainHandler.post { result.success(map) }
                        return
                    }

                    val rawReferrer = bundle.getString("install_referrer")
                    val clickTimestampMs = bundle.getLong("referrer_click_timestamp_milliseconds", 0L)
                    val installBeginTimestampMs = bundle.getLong("install_begin_timestamp_milliseconds", 0L)
                    val appVersion = bundle.getString("app_version")

                    val map = HashMap<String, Any?>()
                    map["status"] = "ok"
                    map["rawReferrer"] = rawReferrer
                    map["referrerClickTimestampMilliseconds"] = clickTimestampMs
                    map["installBeginTimestampMilliseconds"] = installBeginTimestampMs
                    map["appVersion"] = appVersion

                    mainHandler.post { result.success(map) }
                } catch (e: Exception) {
                    mainHandler.post {
                        result.error("BAZAAR_REFERRER_EXCEPTION", e.message, null)
                    }
                } finally {
                    try {
                        context.unbindService(this)
                    } catch (_: Exception) {}
                }
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                // Service disconnected unexpectedly
            }
        }

        try {
            val bound = context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            if (!bound) {
                isCompleted = true
                val map = HashMap<String, Any?>()
                map["status"] = "service_unavailable"
                map["message"] = "Failed to bind to CafeBazaar referrer service"
                result.success(map)
                return
            }

            // Safety timeout after 5 seconds
            mainHandler.postDelayed({
                if (!isCompleted) {
                    isCompleted = true
                    try {
                        context.unbindService(connection)
                    } catch (_: Exception) {}
                    val map = HashMap<String, Any?>()
                    map["status"] = "timeout"
                    map["message"] = "Connection to CafeBazaar referrer timed out"
                    result.success(map)
                }
            }, 5000)
        } catch (e: Exception) {
            isCompleted = true
            result.error("BIND_ERROR", e.message, null)
        }
    }
}
