package com.trackora.googleplay

import android.content.Context
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.android.installreferrer.api.ReferrerDetails
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class TrackoraGooglePlayPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.trackora/google_play")
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
            val pm = context.packageManager
            val playPackage = "com.android.vending"
            val info = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                pm.getPackageInfo(playPackage, android.content.pm.PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(playPackage, 0)
            }
            result.success(info != null)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun fetchReferrer(result: Result) {
        try {
            val client = InstallReferrerClient.newBuilder(context).build()
            client.startConnection(object : InstallReferrerStateListener {
                private var responded = false

                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    if (responded) return
                    responded = true

                    try {
                        when (responseCode) {
                            InstallReferrerClient.InstallReferrerResponse.OK -> {
                                val details: ReferrerDetails = client.installReferrer
                                val map = HashMap<String, Any?>()
                                map["rawReferrer"] = details.installReferrer
                                map["referrerClickTimestampSeconds"] = details.referrerClickTimestampSeconds
                                map["installBeginTimestampSeconds"] = details.installBeginTimestampSeconds
                                map["googlePlayInstantParam"] = details.googlePlayInstantParam
                                map["status"] = "ok"
                                result.success(map)
                            }
                            InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED -> {
                                val map = HashMap<String, Any?>()
                                map["status"] = "feature_not_supported"
                                map["message"] = "Install Referrer API is not supported on this Google Play Store client."
                                result.success(map)
                            }
                            InstallReferrerClient.InstallReferrerResponse.SERVICE_UNAVAILABLE -> {
                                val map = HashMap<String, Any?>()
                                map["status"] = "service_unavailable"
                                map["message"] = "Google Play Referrer service is currently unavailable."
                                result.success(map)
                            }
                            InstallReferrerClient.InstallReferrerResponse.DEVELOPER_ERROR -> {
                                val map = HashMap<String, Any?>()
                                map["status"] = "developer_error"
                                map["message"] = "Google Play Install Referrer developer error."
                                result.success(map)
                            }
                            else -> {
                                val map = HashMap<String, Any?>()
                                map["status"] = "error"
                                map["message"] = "Unknown response code from Google Play: $responseCode"
                                result.success(map)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("PLAY_REFERRER_EXCEPTION", e.message, null)
                    } finally {
                        try {
                            client.endConnection()
                        } catch (_: Exception) {}
                    }
                }

                override fun onInstallReferrerServiceDisconnected() {
                    // Connection dropped
                }
            })
        } catch (e: Exception) {
            result.error("INITIALIZATION_ERROR", e.message, null)
        }
    }
}
