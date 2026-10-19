package com.trackora.myket

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import com.myket.installreferrer.IGetInstallReferrerService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class TrackoraMyketPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        const val MYKET_PACKAGE = "ir.mservices.market"
        const val SERVICE_ACTION = "ir.mservices.market.InstallReferrerService.BIND"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.trackora/myket")
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
                `package` = MYKET_PACKAGE
            }
            val resolved = context.packageManager.queryIntentServices(intent, 0)
            result.success(resolved.isNotEmpty())
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun fetchReferrer(result: Result) {
        val intent = Intent(SERVICE_ACTION).apply {
            `package` = MYKET_PACKAGE
        }

        val resolved = context.packageManager.queryIntentServices(intent, 0)
        if (resolved.isEmpty()) {
            val map = HashMap<String, Any?>()
            map["status"] = "service_unavailable"
            map["message"] = "Myket is not installed or referrer service is unavailable."
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
                    val service = IGetInstallReferrerService.Stub.asInterface(binder)
                    val requestBundle = Bundle().apply {
                        putString("package_name", context.packageName)
                    }

                    val bundle = service.getInstallReferrer(requestBundle)
                    if (bundle == null) {
                        val map = HashMap<String, Any?>()
                        map["status"] = "not_found"
                        map["message"] = "No response bundle from Myket"
                        mainHandler.post { result.success(map) }
                        return
                    }

                    val responseCode = bundle.getInt("response_code", -1)
                    val map = HashMap<String, Any?>()

                    when (responseCode) {
                        0 -> { // OK
                            val rawReferrer = bundle.getString("install_referrer")
                            val clickTimestampSec = bundle.getLong("referrer_click_timestamp_seconds", 0L)
                            val installBeginTimestampSec = bundle.getLong("install_begin_timestamp_seconds", 0L)

                            map["status"] = "ok"
                            map["rawReferrer"] = rawReferrer
                            map["referrerClickTimestampSeconds"] = clickTimestampSec
                            map["installBeginTimestampSeconds"] = installBeginTimestampSec
                        }
                        5 -> { // DEVELOPER_ERROR / Not Authorized
                            map["status"] = "developer_error"
                            map["message"] = "Caller is not authorized to read this package referrer in Myket."
                        }
                        6 -> { // NOT_FOUND
                            map["status"] = "not_found"
                            map["message"] = "No referrer record found in Myket for this package."
                        }
                        else -> {
                            map["status"] = "error"
                            map["message"] = "Myket returned response code: $responseCode"
                        }
                    }

                    mainHandler.post { result.success(map) }
                } catch (e: Exception) {
                    mainHandler.post {
                        result.error("MYKET_REFERRER_EXCEPTION", e.message, null)
                    }
                } finally {
                    try {
                        context.unbindService(this)
                    } catch (_: Exception) {}
                }
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                // Connection dropped
            }
        }

        try {
            val bound = context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            if (!bound) {
                isCompleted = true
                val map = HashMap<String, Any?>()
                map["status"] = "service_unavailable"
                map["message"] = "Failed to bind to Myket referrer service"
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
                    map["message"] = "Connection to Myket referrer timed out"
                    result.success(map)
                }
            }, 5000)
        } catch (e: Exception) {
            isCompleted = true
            result.error("BIND_ERROR", e.message, null)
        }
    }
}
