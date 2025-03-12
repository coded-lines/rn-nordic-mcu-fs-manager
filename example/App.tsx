import React from "react";
import { SafeAreaView } from "react-native";

import DownloadScreen from "./src/DownloadScreen";
import SelectDeviceScreen from "./src/SelectDeviceScreen";

export default function App() {
  const [bleId, setBleId] = React.useState<string | null>(null);

  return (
    <SafeAreaView style={styles.container}>
      {bleId ? (
        <DownloadScreen deviceId={bleId} />
      ) : (
        <SelectDeviceScreen setState={setBleId} />
      )}
    </SafeAreaView>
  );
}

const styles = {
  container: {
    flex: 1,
    backgroundColor: "#eee",
  },
};
