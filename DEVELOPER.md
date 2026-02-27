# Developer Documentation

This document is for contributors who want to build, run, or extend the native module. For usage instructions, see `README.md`.

## Scope and Architecture

`rn-nordic-mcu-fs-manager` is an Expo Modules–based React Native library that exposes a single native module: `RnNordicMcuFsManager`. It currently supports **file download over BLE** using the Nordic McuMgr protocol.

Key points:
- JS/TS entrypoint lives in `src/` and is a thin wrapper around the native module.
- iOS implementation uses `iOSMcuManagerLibrary` via `FileSystemManager`.
- Android implementation uses `io.runtime.mcumgr` via `FsManager`.

## Repository Layout

- `src/` — TypeScript API surface and types.
- `android/` — Kotlin Expo module implementation.
- `ios/` — Swift Expo module implementation and podspec.
- `example/` — Expo app for manual testing.
- `build/` — Generated build artifacts (output of `expo-module build`).

## Prerequisites

- Node.js and npm.
- Xcode + CocoaPods for iOS development.
- Android Studio + Android SDK for Android development.
- A BLE device that exposes the McuMgr FS service and has a readable file.

## Local Development Setup

1. Install root dependencies.
```bash
npm install
```
2. Install example app dependencies.
```bash
cd example
npm install
```
3. iOS only: install CocoaPods for the example app.
```bash
cd ios
npx pod-install
```
4. Run the example app (prebuilds the native projects on first run).
```bash
npm run ios
```
or
```bash
npm run android
```

## Example App Flow

The example app demonstrates scanning for BLE devices and downloading a file:
- `example/src/SelectDeviceScreen.tsx` requests permissions on Android and scans via `react-native-ble-plx`.
- Selecting a device passes its ID to `example/src/DownloadScreen.tsx`.
- `DownloadScreen` calls `fileDownload(deviceId, filename, callbacks...)`.

Notes about device IDs:
- Android expects a MAC address (e.g., `AA:BB:CC:DD:EE:FF`).
- iOS expects a UUID string.

## JS API Contract (Developer View)

The JS module is defined in `src/RnNordicMcuFsManagerModule.ts` and exposes:

`fileDownload(deviceId: string, filename: string, onProgress?, onFailed?, onCanceled?, onCompleted?)`

Callback payloads:
- `onProgress({ currentBytes, totalBytes, timestamp })`
- `onFailed({ code, message, stack? })`
- `onCanceled({ canceled: true })`
- `onCompleted({ data, size })`

Common error codes:
- `INIT_ERROR` — BLE transport or manager initialization failed.
- `START_DOWNLOAD_ERROR` — failed to start the download.
- `MCU_MGR_DOWNLOAD_FAILED` — McuMgr reported an error during transfer.

## Native Implementation Details

Android (`android/src/main/java/.../RnNordicMcuFsManagerModule.kt`):
- Creates `McuMgrBleTransport` from a BLE MAC address.
- Requests MTU 498 and high connection priority.
- Uses `FsManager.fileDownload` and forwards callbacks to JS.
- `destroy()` is a no-op (stateless implementation).

iOS (`ios/RnNordicMcuFsManagerModule.swift`):
- Creates `McuMgrBleTransport` from a UUID string.
- Uses `FileSystemManager.download`.
- `destroy()` closes the transport and clears callbacks.

## Build, Lint, Test

These scripts are provided by `expo-module-scripts`:
- `npm run build`
- `npm run lint`
- `npm run test`
- `npm run clean`

## Troubleshooting

Bluetooth permissions on Android 12+: The example app requests `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`. In a host app, ensure you request and declare the proper permissions.

Device ID mismatch: iOS expects a UUID; Android expects a MAC address. Passing the wrong format will fail initialization.

Download completes but data looks wrong: `onCompleted` returns a `number[]` of bytes (0–255). Convert to text only if the file content is known to be text.

## Extending the Module

If you add new native APIs:
- Update `src/RnNordicMcuFsManagerModule.ts` with new types and method signatures.
- Implement the same method on both iOS and Android.
- Update `README.md` with the public API documentation.
- Add a usage example in `example/`.
