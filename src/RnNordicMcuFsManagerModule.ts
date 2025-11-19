import { NativeModule, requireNativeModule } from "expo";

export type DownloadProgress = {
  currentBytes: number;
  totalBytes: number;
  timestamp: number;
};

export type DownloadError = {
  code: string;
  message: string;
  stack?: string;
};

export type DownloadCanceled = {
  canceled: boolean;
};

export type DownloadResult = {
  data: number[];
  size: number;
};

declare class RnNordicMcuFsManagerModule extends NativeModule {
  fileDownload(
    deviceId: string,
    filename: string,
    onDownloadProgressChanged?: (progress: DownloadProgress) => void,
    onDownloadFailed?: (error: DownloadError) => void,
    onDownloadCanceled?: (info: DownloadCanceled) => void,
    onDownloadCompleted?: (result: DownloadResult) => void,
  ): void;
}

export default requireNativeModule<RnNordicMcuFsManagerModule>(
  "RnNordicMcuFsManager",
);
