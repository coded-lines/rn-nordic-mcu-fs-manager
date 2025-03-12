import { Alert, Button, ScrollView, Text, View } from "react-native";
import RnNordicMcuFsManager from "rn-nordic-mcu-fs-manager";

type Props = {
  deviceId: string;
};

const DownloadScreen: React.FC<Props> = ({ deviceId }) => {
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
    Alert.alert("Download Completed", result);
  };
  return (
    <ScrollView style={styles.container}>
      <Text style={styles.header}>Module API Example</Text>
      <Group name="Functions">
        <Button
          title="Download File"
          onPress={async () => {
            try {
              console.log("JS: Downloading file");
              fsManager.initialize(deviceId);
              fsManager.fileDownload(
                "/lfs1/Lorem_1000.txt",
                onDownloadProgressChanged,
                onDownloadFailed,
                onDownloadCanceled,
                onDownloadCompleted,
              );
            } catch (error) {
              console.log("JS: Error downloading file");
              console.error(error);
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
