import {
  FlatList,
  StyleSheet,
  View,
  Text,
  Button,
  PermissionsAndroid,
} from "react-native";

import useBluetoothDevices from "./useBluetoothDevice";

type ScreenProps = {
  setState: React.Dispatch<React.SetStateAction<string | null>>;
};

const SelectDeviceScreen: React.FC<ScreenProps> = ({ setState }) => {
  const { devices, error: scanError } = useBluetoothDevices();
  return (
    <>
      <Button
        title="Request Permissions (Android only)"
        onPress={async () => {
          await PermissionsAndroid.request(
            PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
          );
          await PermissionsAndroid.request(
            PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
          );
        }}
      />
      <FlatList
        contentContainerStyle={styles.list}
        data={devices}
        keyExtractor={({ id }) => id}
        renderItem={({ item }) => (
          <View>
            <Text>{item.name || item.id}</Text>

            <Button
              title="Select"
              onPress={() => {
                console.log(item.id);
                setState(item.id);
              }}
            />
          </View>
        )}
        ListHeaderComponent={() => <Text>{scanError}</Text>}
      />
    </>
  );
};

const styles = StyleSheet.create({
  list: {
    padding: 16,
  },
});

export default SelectDeviceScreen;
