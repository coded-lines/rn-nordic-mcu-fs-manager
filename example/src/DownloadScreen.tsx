import React from "react";
import { Alert, Button, ScrollView, Text, View } from "react-native";
import RnNordicMcuFsManager, {
  type DownloadProgress,
  type DownloadError,
  type DownloadResult,
} from "rn-nordic-mcu-fs-manager";

type Props = {
  deviceId: string;
};

const DownloadScreen: React.FC<Props> = ({ deviceId }) => {
  const fsManager = RnNordicMcuFsManager;

  const onDownloadProgressChanged = (progress: DownloadProgress) => {
    const { currentBytes, totalBytes } = progress;
    const percent =
      totalBytes > 0 ? ((currentBytes / totalBytes) * 100).toFixed(1) : "0.0";

    console.log(
      `Progress: ${currentBytes}/${totalBytes} (${percent}%)`,
      progress,
    );
  };

  const onDownloadFailed = (error: DownloadError) => {
    console.log("Failed:", error);
    Alert.alert(
      "Download Failed",
      error.message || "Unknown error downloading file",
    );
  };

  const onDownloadCanceled = () => {
    console.log("Canceled");
    Alert.alert("Download Canceled");
  };

  const onDownloadCompleted = (result: DownloadResult) => {
    // result.data is number[] (0–255)
    const text = String.fromCharCode(...result.data);
    console.log("Completed, bytes:", result.size);
    console.log("Result text:", text);

    Alert.alert("Download Completed", text);
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.header}>Module API Example</Text>
      <Group name="Functions">
        <Button
          title="Download File"
          onPress={async () => {
            if (!deviceId) {
              Alert.alert("Error", "No deviceId provided");
              return;
            }

            try {
              console.log(
                "JS: Starting file download for device:",
                deviceId,
                "file:",
                "/lfs1/Lorem_1000.txt",
              );

              fsManager.fileDownload(
                deviceId,
                "/lfs1/Lorem_1000.txt",
                onDownloadProgressChanged,
                onDownloadFailed,
                onDownloadCanceled,
                onDownloadCompleted,
              );
            } catch (error) {
              console.log("JS: Error calling fileDownload");
              console.error(error);
              Alert.alert("Error", String(error));
            }
          }}
        />
      </Group>
    </ScrollView>
  );
};

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
  },
  group: {
    margin: 20,
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: "#eee",
  },
};

export default DownloadScreen;
