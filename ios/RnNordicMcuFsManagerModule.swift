import ExpoModulesCore
import iOSMcuManagerLibrary

public class RnNordicMcuFsManagerModule: Module, FileDownloadDelegate {
    private var transport: McuMgrBleTransport?
    private var fsManager: FileSystemManager?
    
    private var jsProgressCallback : JavaScriptFunction<ExpressibleByNilLiteral>?
    private var jsFailedCallback : JavaScriptFunction<ExpressibleByNilLiteral>?
    private var jsCanceledCallback : JavaScriptFunction<ExpressibleByNilLiteral>?
    private var jsCompletedCallback : JavaScriptFunction<ExpressibleByNilLiteral>?
    
    public func downloadProgressDidChange(bytesDownloaded: Int, fileSize: Int, timestamp: Date) {
        let progress = Double(bytesDownloaded) / Double(fileSize) * 100
        print("Download progress: \(progress)% at \(timestamp)")
        self.appContext?.executeOnJavaScriptThread {
            do {
                let _ = try self.jsProgressCallback?.call(progress)
            } catch let err {
                print(
                    "Failed to call progress callback: \(err.localizedDescription)"
                )
            }
        }
    }
    
    public func downloadDidFail(with error: Error) {
        print("Download failed with error: \(error.localizedDescription)")
        self.appContext?.executeOnJavaScriptThread {
            do {
                let _ = try self.jsFailedCallback?.call(error.localizedDescription)
            } catch let err {
                print("Failed to call failed callback: \(err.localizedDescription)")
            }
        }
    }
    
    public func downloadDidCancel() {
        print("Download was canceled")
        self.appContext?.executeOnJavaScriptThread {
            do {
                let _ = try self.jsCanceledCallback?.call()
            } catch let err {
                print("Failed to call cancelled callback: \(err.localizedDescription)")
            }
        }
    }
    
    public func download(of name: String, didFinish data: Data) {
        print("Download of \(name) finished successfully.")
        self.appContext?.executeOnJavaScriptThread {
            do {
                let _ = try self.jsCompletedCallback?.call(data)
            } catch let err {
                print("Failed to call completed callback: \(err.localizedDescription)")
            }
        }
    }
    
    // Each module class must implement the definition function. The definition consists of components
    // that describes the module's functionality and behavior.
    // See https://docs.expo.dev/modules/module-api for more details about available components.
    public func definition() -> ModuleDefinition {
        // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
        // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
        // The module will be accessible from `requireNativeModule('RnNordicMcuFsManager')` in JavaScript.
        Name("RnNordicMcuFsManager")
        
        Function("initialize") { (bleId: String) in
            guard let bleUuid = UUID(uuidString: bleId) else {
                print("Failed to parse UUID")
                throw Exception(name: "UUIDParseError", description: "Failed to parse UUID")
            }
            transport = McuMgrBleTransport(bleUuid)
            fsManager = FileSystemManager(transport: transport!)
            
        }
        
        Function("destroy") {
            var hasError: Error? = nil
            fsManager?.closeAll(name: "", callback: { (response: McuMgrResponse?, error: Error?) in
                if let response = response {
                    print("Received response: \(response)")
                } else if let error = error {
                    hasError = error
                    print("Error: \(error)")
                } else {
                    print("No response or error received")
                }
            })
            if hasError != nil {
                throw Exception(name: "ConnectionCloseError", description: hasError?.localizedDescription ?? "Failed to close connection")
            }
            transport?.close()
        }
        
        Function("fileDownload") {
            (filename: String,
             progressCallback: JavaScriptFunction<ExpressibleByNilLiteral>,
             failedCallback: JavaScriptFunction<ExpressibleByNilLiteral>,
             canceledCallback: JavaScriptFunction<ExpressibleByNilLiteral>,
             completedCallback: JavaScriptFunction<ExpressibleByNilLiteral>) in
            self.jsProgressCallback = progressCallback
            self.jsFailedCallback = failedCallback
            self.jsCanceledCallback = canceledCallback
            self.jsCompletedCallback = completedCallback
            
            _ = fsManager!.download(name: filename, delegate: self)
        }
    }
}
