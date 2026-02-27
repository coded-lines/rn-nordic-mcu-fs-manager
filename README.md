# React Native Nordic MCU Filesystem Manager

React Native Nordic MCU Filesystem Manager (currently supports only download functionality)

## Table of Contents

- [Installation](#installation-in-managed-expo-projects)
- [Usage](#usage)
- [Developer Documentation](#developer-documentation)
- [API Documentation](#api)
- [Contributing](#contributing)
- [Credits](#credits)

## Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects, please follow the installation instructions in the [API documentation for the latest stable release](#api-documentation). If you follow the link and there is no documentation available then this library is not yet usable within managed projects &mdash; it is likely to be included in an upcoming Expo SDK release.

## Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```
npm install rn-nordic-mcu-fs-manager
```

### Configure for Android

No configuration needed.


### Configure for iOS

Run `npx pod-install` after installing the npm package.


## Usage

### 1. Import the Module

```javascript
import RnNordicMcuFsManager from "rn-nordic-mcu-fs-manager";
```

### 2. Using the Module

Here's an example of how you can use the module in your application:

```javascript

const App = () => {
  const fsManager = RnNordicMcuFsManager;

  const onDownloadProgressChanged = (progress: number) => {
    console.log("Progress: ", progress);
  };
  const onDownloadFailed = (error: string) => {
    console.log("Failed: ", error);
  };
  const onDownloadCanceled = () => {
    console.log("Canceled");
  };
  const onDownloadCompleted = (bytearray: number[]) => {
    fsManager.destroy();
    const result = String.fromCharCode(...bytearray);
    console.log("Completed", result);
  };

  return (
    <View>
      <Button
        title="Download File"
        onPress={async () => {
          try {
            fsManager.initialize(deviceId);
            fsManager.fileDownload(
              "/lfs1/Lorem_1000.txt",
              onDownloadProgressChanged,
              onDownloadFailed,
              onDownloadCanceled,
              onDownloadCompleted,
            );
          } catch (error) {
            console.error(error);
          }
        }}
      />
    </View>
  );
};

export default App;
```

Make sure to check the documentation for all available functions and their expected usage.

---

## Developer Documentation

See `DEVELOPER.md` for local setup, architecture notes, and contributor guidance.

## API Documentation

- [initialize](#initialize)
- [destroy](#destroy)
- [fileDownload](#file-download)

## Methods

### Initialize
### `initialize(bleId: string)`

**Description:**
Creates a connection with the bluetooth device and initializes a filesystem manager module.

**Parameters:**

- `bleId` (`string`):
    For Android the device's mac address, for iOS the device's UUID

---

### Destroy
### `destroy()`

**Description:**
Closes the connection with the bluetooth device and releases all the native modules.

---


### File Download
### `fileDownload(filePath: string, onDownloadProgressChanged: function, onDownloadFailed: function, onDownloadCanceled: function, onDownloadCompleted: function)`

**Description:**  
Initiates a file download operation from the specified `filePath`. The method provides various callbacks to handle download progress, failure, cancellation, and completion.

**Parameters:**

- `filePath` (`string`):  
  The path to the file that you want to download (e.g., `"/lfs1/Lorem_1000.txt"`).
  
- `onDownloadProgressChanged` (`function`):  
  A callback function that will be called with the current download progress (e.g., `onDownloadProgressChanged(progress)`), where `progress` is a number between `0` and `100`.

- `onDownloadFailed` (`function`):  
  A callback function that will be called if the download fails. It receives an error message as a parameter (e.g., `onDownloadFailed(error)`).

- `onDownloadCanceled` (`function`):  
  A callback function that will be called if the download is canceled. It receives no parameters (e.g., `onDownloadCanceled()`).

- `onDownloadCompleted` (`function`):  
  A callback function that will be called when the download is completed successfully. It receives the downloaded byte array and must be converted to string (e.g., `onDownloadCompleted(byteArray)`).








## Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide]( https://github.com/expo/expo#contributing).

### Run the module locally

```
git clone git@github.com:coded-lines/rn-nordic-mcu-fs-manager.git && cd rn-nordic-mcu-fs-manager && npm install && cd example && npm install && cd ios && npx pod-install && cd .. && npx expo prebuild
```

---

### Credits

This project is heavily inspired by and takes code from [react-native-mcu-manager](https://github.com/PlayerData/react-native-mcu-manager)
