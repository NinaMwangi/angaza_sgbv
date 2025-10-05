import { PermissionsAndroid, Platform, Alert } from 'react-native';

export const requestAllPermissions = async () => {
  if (Platform.OS === 'android') {
    try {
      const granted = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION,
        PermissionsAndroid.PERMISSIONS.SEND_SMS,
      ]);

      const allGranted = Object.values(granted).every(
        status => status === PermissionsAndroid.RESULTS.GRANTED
      );

      if (!allGranted) {
        Alert.alert(
          'Permissions Required',
          'This app needs all permissions to function properly for your safety.',
          [{ text: 'OK' }]
        );
      }

      return allGranted;
    } catch (err) {
      console.warn('Permission error:', err);
      return false;
    }
  }
  return true; // iOS permissions are requested automatically
};

export const checkLocationPermission = async () => {
  if (Platform.OS === 'android') {
    const granted = await PermissionsAndroid.check(
      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
    );
    return granted;
  }
  return true;
};

export const checkAudioPermission = async () => {
  if (Platform.OS === 'android') {
    const granted = await PermissionsAndroid.check(
      PermissionsAndroid.PERMISSIONS.RECORD_AUDIO
    );
    return granted;
  }
  return true;
};