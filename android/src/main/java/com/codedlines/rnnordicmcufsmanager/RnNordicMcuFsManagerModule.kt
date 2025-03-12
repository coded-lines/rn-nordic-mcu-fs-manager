package com.codedlines.rnnordicmcufsmanager

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.util.Log
import expo.modules.kotlin.jni.JavaScriptFunction
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import io.runtime.mcumgr.McuMgrTransport
import io.runtime.mcumgr.ble.McuMgrBleTransport
import io.runtime.mcumgr.exception.McuMgrException
import io.runtime.mcumgr.managers.FsManager
import io.runtime.mcumgr.transfer.DownloadCallback

private const val TAG = "RnNordicMcuFsManagerModule"

class RnNordicMcuFsManagerModule : Module() {
    private lateinit var fsManager: FsManager
    private lateinit var device: BluetoothDevice
    private lateinit var transport: McuMgrTransport

    private val context
        get() = requireNotNull(appContext.reactContext) { "React Application Context is null" }

    private fun getBluetoothDevice(macAddress: String?): BluetoothDevice {
        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = bluetoothManager.adapter ?: throw Exception("No bluetooth adapter")

        return adapter.getRemoteDevice(macAddress)
    }

    // Each module class must implement the definition function. The definition consists of components
    // that describes the module's functionality and behavior.
    // See https://docs.expo.dev/modules/module-api for more details about available components.
    override fun definition() = ModuleDefinition {
        // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
        // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
        // The module will be accessible from `requireNativeModule('RnNordicMcuFsManager')` in JavaScript.
        Name("RnNordicMcuFsManager")

        Function("initialize") { macAddress: String ->
            device = getBluetoothDevice(macAddress)
            transport = McuMgrBleTransport(context, device)
            fsManager = FsManager(transport as McuMgrBleTransport)
            Log.d(TAG, "Initialized")
        }

        Function("destroy") {
            fsManager.closeAll()
            transport.release()
        }

        Function("fileDownload") { filename: String, progressCallback: JavaScriptFunction<Unit>, failedCallback: JavaScriptFunction<Unit>, canceledCallback: JavaScriptFunction<Unit>, completedCallback: JavaScriptFunction<Unit> ->
            val downloadCallback = object : DownloadCallback {
                override fun onDownloadProgressChanged(var1: Int, var2: Int, var3: Long) {
                    appContext.executeOnJavaScriptThread {
                        progressCallback(var1, var2, var3)
                    }
                    Log.d(TAG, "Progress changed, $var1, $var2, $var3")
                }

                override fun onDownloadFailed(var1: McuMgrException) {
                    appContext.executeOnJavaScriptThread {
                        failedCallback(var1)
                    }
                    Log.d(TAG, "Download failed")
                }

                override fun onDownloadCanceled() {
                    appContext.executeOnJavaScriptThread {
                        canceledCallback()
                    }
                    Log.d(TAG, "Download canceled")
                }

                override fun onDownloadCompleted(var1: ByteArray) {
                    Log.d(TAG, "Download completed $var1")
                    appContext.executeOnJavaScriptThread {
                        completedCallback(var1)
                    }
                }

            }

            fsManager.fileDownload(filename, downloadCallback)
        }
    }
}
