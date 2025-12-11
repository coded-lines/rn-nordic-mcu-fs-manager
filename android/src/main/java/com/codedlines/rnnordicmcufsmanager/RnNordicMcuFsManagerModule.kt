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

    private val context: Context
        get() = appContext.reactContext
            ?: appContext.currentActivity
            ?: throw IllegalStateException("React or Activity context is null")

    private fun getBluetoothDevice(macAddress: String): BluetoothDevice {
        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                ?: throw IllegalStateException("BluetoothManager not available")

        val adapter = bluetoothManager.adapter
            ?: throw IllegalStateException("No Bluetooth adapter available")

        return try {
            adapter.getRemoteDevice(macAddress)
        } catch (e: IllegalArgumentException) {
            throw IllegalArgumentException("Invalid MAC / device id: $macAddress", e)
        }
    }

    private fun safeInvokeCallback(
        callback: JavaScriptFunction<Any?>?,
        payload: Any? = null
    ) {
        if (callback == null) return

        appContext.executeOnJavaScriptThread {
            try {
                if (payload != null) {
                    callback.invoke(payload)
                } else {
                    callback.invoke()
                }
            } catch (t: Throwable) {
                Log.e(TAG, "Error while invoking JS callback", t)
            }
        }
    }

    override fun definition() = ModuleDefinition {
        Name("RnNordicMcuFsManager")

        /**
         * destroy() – no-op for stateless implementation, kept for API compatibility.
         */
        Function("destroy") {
            Log.d(TAG, "destroy() called – stateless implementation, nothing to clean up")
        }

        /**
         * fileDownload(
         *   deviceId: string,
         *   filename: string,
         *   onDownloadProgressChanged?: (progress: { currentBytes, totalBytes, timestamp }) => void,
         *   onDownloadFailed?: (error: { code, message, stack? }) => void,
         *   onDownloadCanceled?: (info: { canceled: true }) => void,
         *   onDownloadCompleted?: (result: { data: number[], size: number }) => void
         * )
         */
        Function("fileDownload") {
                macAddress: String,
                filename: String,
                onDownloadProgressChanged: JavaScriptFunction<Any?>?,
                onDownloadFailed: JavaScriptFunction<Any?>?,
                onDownloadCanceled: JavaScriptFunction<Any?>?,
                onDownloadCompleted: JavaScriptFunction<Any?>?
            ->

            Log.d(TAG, "fileDownload() called with mac=$macAddress, filename=$filename")

            val device: BluetoothDevice
            val transport = McuMgrBleTransport(context, device).apply {
                setInitialMtu(498)            // default, but make it explicit
                setMaxPacketLength(498)       // allow full-size SMP frames
                requestConnPriority(BluetoothGatt.CONNECTION_PRIORITY_HIGH)
            }
            val manager: FsManager

            try {
                device = getBluetoothDevice(macAddress)
                transport = McuMgrBleTransport(context, device)
                manager = FsManager(transport)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to create transport / FsManager", e)
                val payload = mapOf(
                    "code" to "INIT_ERROR",
                    "message" to (e.message ?: "Failed to init transport or FsManager"),
                    "stack" to e.stackTraceToString()
                )
                safeInvokeCallback(onDownloadFailed, payload)
                throw e
            }

            fun releaseTransport() {
                try {
                    (transport as? McuMgrBleTransport)?.release()
                } catch (e: Exception) {
                    Log.e(TAG, "Error releasing transport", e)
                }
            }

            val downloadCallback = object : DownloadCallback {
                override fun onDownloadProgressChanged(
                    current: Int,
                    total: Int,
                    timestamp: Long
                ) {
                    Log.d(
                        TAG,
                        "Download progress: current=$current, total=$total, timestamp=$timestamp"
                    )

                    val payload = mapOf(
                        "currentBytes" to current,
                        "totalBytes" to total,
                        "timestamp" to timestamp
                    )

                    safeInvokeCallback(onDownloadProgressChanged, payload)
                }

                override fun onDownloadFailed(e: McuMgrException) {
                    Log.e(TAG, "Download failed", e)

                    val payload = mapOf(
                        "code" to "MCU_MGR_DOWNLOAD_FAILED",
                        "message" to (e.message ?: "Unknown McuMgrException"),
                        "stack" to e.stackTraceToString()
                    )

                    safeInvokeCallback(onDownloadFailed, payload)
                    releaseTransport()
                }

                override fun onDownloadCanceled() {
                    Log.w(TAG, "Download canceled")

                    val payload = mapOf(
                        "canceled" to true
                    )

                    safeInvokeCallback(onDownloadCanceled, payload)
                    releaseTransport()
                }

                override fun onDownloadCompleted(data: ByteArray) {
                    Log.d(TAG, "Download completed, bytes=${data.size}")

                    val bytes: List<Int> = data.map { it.toInt() and 0xFF }

                    val payload = mapOf(
                        "data" to bytes,
                        "size" to data.size
                    )

                    safeInvokeCallback(onDownloadCompleted, payload)
                    releaseTransport()
                }
            }

            try {
                Log.d(TAG, "Starting file download over mcumgr")
                manager.fileDownload(filename, downloadCallback)
            } catch (e: Exception) {
                Log.e(TAG, "Error starting file download for: $filename", e)

                val payload = mapOf(
                    "code" to "START_DOWNLOAD_ERROR",
                    "message" to (e.message ?: "Unknown error starting download"),
                    "stack" to e.stackTraceToString()
                )

                safeInvokeCallback(onDownloadFailed, payload)
                releaseTransport()
                throw e
            }
        }
    }
}
