import ExpoModulesCore
import iOSMcuManagerLibrary

public class RnNordicMcuFsManagerModule: Module, FileDownloadDelegate {
  private var transport: McuMgrBleTransport?
  private var fsManager: FileSystemManager?

  private var jsProgressCallback: JavaScriptFunction<[String: Any?]>?
  private var jsFailedCallback: JavaScriptFunction<[String: Any?]>?
  private var jsCanceledCallback: JavaScriptFunction<[String: Any?]>?
  private var jsCompletedCallback: JavaScriptFunction<[String: Any?]>?

  // Helper to safely call JS callbacks on the JS thread
  private func callCallback(
    _ callback: JavaScriptFunction<[String: Any?]>?,
    payload: [String: Any?]
  ) {
    guard let appContext = self.appContext, let cb = callback else {
      return
    }

    appContext.executeOnJavaScriptThread {
      do {
        _ = try cb.call(payload)
      } catch let err {
        print("RnNordicMcuFsManagerModule: Failed to call JS callback: \(err.localizedDescription)")
      }
    }
  }

  // MARK: - FileDownloadDelegate

  public func downloadProgressDidChange(
    bytesDownloaded: Int,
    fileSize: Int,
    timestamp: Date
  ) {
    print("RnNordicMcuFsManagerModule: Download progress \(bytesDownloaded)/\(fileSize) at \(timestamp)")

    let payload: [String: Any?] = [
      "currentBytes": bytesDownloaded,
      "totalBytes": fileSize,
      // milliseconds since epoch, similar to Android's Long timestamp
      "timestamp": Int(timestamp.timeIntervalSince1970 * 1000)
    ]

    callCallback(jsProgressCallback, payload: payload)
  }

  public func downloadDidFail(with error: Error) {
    print("RnNordicMcuFsManagerModule: Download failed with error: \(error.localizedDescription)")

    let payload: [String: Any?] = [
      "code": "MCU_MGR_DOWNLOAD_FAILED",
      "message": error.localizedDescription,
      "stack": String(describing: error)
    ]

    callCallback(jsFailedCallback, payload: payload)
    cleanupTransport()
  }

  public func downloadDidCancel() {
    print("RnNordicMcuFsManagerModule: Download was canceled")

    let payload: [String: Any?] = [
      "canceled": true
    ]

    callCallback(jsCanceledCallback, payload: payload)
    cleanupTransport()
  }

  public func download(of name: String, didFinish data: Data) {
    print("RnNordicMcuFsManagerModule: Download of \(name) finished successfully, bytes=\(data.count)")

    // Data -> [Int] (0–255) to match Android’s List<Int>
    let bytes: [Int] = data.map { Int($0) & 0xFF }

    let payload: [String: Any?] = [
      "data": bytes,
      "size": data.count
    ]

    callCallback(jsCompletedCallback, payload: payload)
    cleanupTransport()
  }

  private func cleanupTransport() {
    // Close filesystem manager & BLE transport
    fsManager = nil
    transport?.close()
    transport = nil

    jsProgressCallback = nil
    jsFailedCallback = nil
    jsCanceledCallback = nil
    jsCompletedCallback = nil
  }

  // MARK: - Module definition

  public func definition() -> ModuleDefinition {
    Name("RnNordicMcuFsManager")

    /**
     * destroy() – stateless implementation, just ensures we close any active transport.
     */
    Function("destroy") {
      print("RnNordicMcuFsManagerModule: destroy() called")
      self.cleanupTransport()
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
      (
        deviceId: String,
        filename: String,
        progressCallback: JavaScriptFunction<[String: Any?]>?,
        failedCallback: JavaScriptFunction<[String: Any?]>?,
        canceledCallback: JavaScriptFunction<[String: Any?]>?,
        completedCallback: JavaScriptFunction<[String: Any?]>?
      ) in

      print("RnNordicMcuFsManagerModule: fileDownload(deviceId=\(deviceId), filename=\(filename))")

      // Store callbacks
      self.jsProgressCallback = progressCallback
      self.jsFailedCallback = failedCallback
      self.jsCanceledCallback = canceledCallback
      self.jsCompletedCallback = completedCallback

      // Init transport + FS manager for this download (stateless like Android)
      guard let uuid = UUID(uuidString: deviceId) else {
        let msg = "Failed to parse UUID from deviceId: \(deviceId)"
        print("RnNordicMcuFsManagerModule: \(msg)")

        let payload: [String: Any?] = [
          "code": "INIT_ERROR",
          "message": msg,
          "stack": msg
        ]
        self.callCallback(failedCallback, payload: payload)
        return
      }

      do {
        self.transport = McuMgrBleTransport(uuid)
        guard let transport = self.transport else {
          let msg = "Failed to create McuMgrBleTransport"
          print("RnNordicMcuFsManagerModule: \(msg)")
          let payload: [String: Any?] = [
            "code": "INIT_ERROR",
            "message": msg,
            "stack": msg
          ]
          self.callCallback(failedCallback, payload: payload)
          return
        }

        self.fsManager = FileSystemManager(transport: transport)

        guard let fsManager = self.fsManager else {
          let msg = "Failed to create FileSystemManager"
          print("RnNordicMcuFsManagerModule: \(msg)")
          let payload: [String: Any?] = [
            "code": "INIT_ERROR",
            "message": msg,
            "stack": msg
          ]
          self.callCallback(failedCallback, payload: payload)
          self.cleanupTransport()
          return
        }

        _ = fsManager.download(name: filename, delegate: self)
      } catch let err {
        print("RnNordicMcuFsManagerModule: Error starting file download: \(err.localizedDescription)")
        let payload: [String: Any?] = [
          "code": "START_DOWNLOAD_ERROR",
          "message": err.localizedDescription,
          "stack": String(describing: err)
        ]
        self.callCallback(failedCallback, payload: payload)
        self.cleanupTransport()
      }
    }
  }
}
