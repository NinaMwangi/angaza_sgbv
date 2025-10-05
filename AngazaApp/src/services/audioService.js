import { Recorder } from '@react-native-community/audio-toolkit';
import { Platform, PermissionsAndroid, Alert } from 'react-native';
import RNFS from 'react-native-fs';

let recorder = null;

export const requestPermissions = async () => {
  if (Platform.OS !== 'android') return true;

  try {
    const permissions = [
      PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
      PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE,
      PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE,
    ];

    const results = await PermissionsAndroid.requestMultiple(permissions);

    const allGranted = permissions.every(
      (perm) => results[perm] === PermissionsAndroid.RESULTS.GRANTED
    );

    if (!allGranted) {
      Alert.alert(
        'Permissions Required',
        'This app needs microphone and storage permissions to record audio. Please grant them in Settings.',
        [{ text: 'OK' }]
      );
      return false;
    }
    return true;
  } catch (error) {
    console.error('Permission request error:', error);
    return false;
  }
};

export const startRecording = async () => {
  try {
    const hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      throw new Error('Permissions denied');
    }

    const path = Platform.select({
      ios: `${RNFS.DocumentDirectoryPath}/emergency_audio.m4a`,
      android: `${RNFS.ExternalDirectoryPath}/emergency_audio.m4a`,
    });

    recorder = new Recorder(path, {
      format: 'm4a',
      encoder: 'aac',
      sampleRate: 44100,
      bitrate: 128000,
    });

    const result = await recorder.prepare().record();
    console.log('Recording started:', result);

    recorder.on('progress', (data) => {
      console.log('Recording time:', data.currentPosition / 1000); // Convert ms to seconds
    });

    return result;
  } catch (error) {
    console.error('Recording error:', error);
    throw error;
  }
};

export const stopRecording = async () => {
  try {
    if (!recorder) {
      throw new Error('Recorder not initialized');
    }
    const result = await recorder.stop();
    console.log('Recording stopped:', result);
    recorder = null;
    return result;
  } catch (error) {
    console.error('Stop recording error:', error);
    throw error;
  }
};

export const getAudioDuration = async () => {
  try {
    if (!recorder) {
      return '0:00';
    }
    const duration = recorder.duration / 1000; // Convert ms to seconds
    const minutes = Math.floor(duration / 60);
    const seconds = Math.floor(duration % 60);
    return `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
  } catch (error) {
    console.error('Duration error:', error);
    return '0:00';
  }
};