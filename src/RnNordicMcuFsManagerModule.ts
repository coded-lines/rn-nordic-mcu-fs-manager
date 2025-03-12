import { NativeModule, requireNativeModule } from "expo";

declare class RnNordicMcuFsManagerModule extends NativeModule {
  initialize(bleId: string): void;
  destroy(): void;
  fileDownload(
    filename: string,
    onDownloadProgressChanged: (progress: number) => void,
    onDownloadFailed: (error: string) => void,
    onDownloadCanceled: () => void,
    onDownloadCompleted: (bytearray: number[]) => void
  ): void;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RnNordicMcuFsManagerModule>(
  "RnNordicMcuFsManager"
);
