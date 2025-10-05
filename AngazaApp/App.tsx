// ============================================
// COMPLETE INTEGRATED APP WITH ALL SERVICES
// ============================================

// App.js - Main Application
import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  StatusBar,
  Alert,
  ScrollView,
  TextInput,
  Modal,
  Platform,
  PermissionsAndroid,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Import services (we'll create these)
import * as AudioService from './src/services/audioService';
import * as LocationService from './src/services/locationService';
import * as SensorService from './src/services/sensorService';
import * as SMSService from './src/services/smsService';

const Tab = createBottomTabNavigator();

// Icons
const HomeIcon = () => <Text style={styles.tabIcon}>🏠</Text>;
const ContactsIcon = () => <Text style={styles.tabIcon}>👥</Text>;
const SettingsIcon = () => <Text style={styles.tabIcon}>⚙️</Text>;

// ============================================
// PERMISSIONS UTILITY
// ============================================
const requestAllPermissions = async () => {
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
  return true;
};

// ============================================
// HOME SCREEN - Main SOS Interface
// ============================================
function HomeScreen() {
  const [isRecording, setIsRecording] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [location, setLocation] = useState(null);
  const [sosHistory, setSosHistory] = useState([]);
  const [recordingTime, setRecordingTime] = useState(0);
  const [sensorMonitoring, setSensorMonitoring] = useState(false);

  useEffect(() => {
    loadSosHistory();
    requestAllPermissions();
    getCurrentLocationData();
  }, []);

  const loadSosHistory = async () => {
    try {
      const history = await AsyncStorage.getItem('sosHistory');
      if (history) setSosHistory(JSON.parse(history));
    } catch (error) {
      console.error('Error loading history:', error);
    }
  };

  const getCurrentLocationData = async () => {
    try {
      const loc = await LocationService.getCurrentLocation();
      const address = await LocationService.getAddressFromCoordinates(
        loc.latitude,
        loc.longitude
      );
      setLocation({ ...loc, address });
    } catch (error) {
      console.error('Location error:', error);
      setLocation({
        latitude: -1.2921,
        longitude: 36.8219,
        address: 'Location unavailable'
      });
    }
  };

  const triggerSOS = async () => {
    try {
      setIsRecording(true);
      setRecordingTime(0);

      // Start recording countdown
      const interval = setInterval(() => {
        setRecordingTime(prev => prev + 1);
      }, 1000);

      // 1. Start audio recording
      Alert.alert('Recording', 'Speak clearly. Recording your emergency message...');
      await AudioService.startRecording();

      // 2. Record for 30 seconds
      await new Promise(resolve => setTimeout(resolve, 30000));

      // 3. Stop recording
      clearInterval(interval);
      const audioPath = await AudioService.stopRecording();
      
      setIsRecording(false);
      setIsProcessing(true);

      // 4. Get current location
      const currentLocation = await LocationService.getCurrentLocation();
      const address = await LocationService.getAddressFromCoordinates(
        currentLocation.latitude,
        currentLocation.longitude
      );

      // 5. Get emergency contacts
      const contactsJson = await AsyncStorage.getItem('emergencyContacts');
      const contacts = contactsJson ? JSON.parse(contactsJson) : [];

      if (contacts.length === 0) {
        throw new Error('No emergency contacts configured. Please add contacts first.');
      }

      // 6. Create emergency message
      const emergencyMessage = `Emergency assistance needed. Audio message recorded. Please respond immediately.`;

      // 7. Send SMS to all contacts
      await SMSService.sendEmergencySMS(contacts, emergencyMessage, {
        ...currentLocation,
        address,
      });

      // 8. Save to history
      const sosRecord = {
        id: Date.now(),
        timestamp: new Date().toISOString(),
        message: emergencyMessage,
        audioPath: audioPath,
        location: { ...currentLocation, address },
        status: 'sent',
        contactsNotified: contacts.length,
      };

      const newHistory = [sosRecord, ...sosHistory];
      setSosHistory(newHistory);
      await AsyncStorage.setItem('sosHistory', JSON.stringify(newHistory));

      setIsProcessing(false);

      Alert.alert(
        '✓ SOS Sent Successfully',
        `${contacts.length} emergency contact(s) have been notified with your location and audio message.`,
        [{ text: 'OK' }]
      );

    } catch (error) {
      setIsRecording(false);
      setIsProcessing(false);
      console.error('SOS Error:', error);
      
      Alert.alert(
        'Error',
        error.message || 'Failed to send SOS. Please try again or contact emergency services directly.',
        [
          { text: 'Retry', onPress: triggerSOS },
          { text: 'Cancel', style: 'cancel' }
        ]
      );
    }
  };

  const handleSOSPress = () => {
    Alert.alert(
      '🆘 Trigger Emergency SOS',
      'This will:\n• Record 30 seconds of audio\n• Send your location to emergency contacts\n• Notify all configured contacts',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Send SOS', onPress: triggerSOS, style: 'destructive' }
      ]
    );
  };

  const toggleSensorMonitoring = () => {
    if (sensorMonitoring) {
      SensorService.stopSensorMonitoring();
      setSensorMonitoring(false);
      Alert.alert('Monitoring Stopped', 'Dormancy detection has been disabled.');
    } else {
      SensorService.startSensorMonitoring((timeSinceMovement) => {
        Alert.alert(
          'Dormancy Detected',
          `No movement detected for ${Math.floor(timeSinceMovement / 60000)} minutes. Are you okay?`,
          [
            { text: "I'm OK", style: 'cancel' },
            { text: 'Send SOS', onPress: triggerSOS, style: 'destructive' }
          ]
        );
      });
      setSensorMonitoring(true);
      Alert.alert('Monitoring Active', 'Dormancy detection is now active.');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#fff" />
      
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Weather App</Text>
        <Text style={styles.headerSubtitle}>Stay Prepared</Text>
      </View>

      <ScrollView style={styles.content}>
        {/* Main SOS Button */}
        <View style={styles.sosContainer}>
          <TouchableOpacity
            style={[
              styles.sosButton,
              (isRecording || isProcessing) && styles.sosButtonActive
            ]}
            onPress={handleSOSPress}
            disabled={isRecording || isProcessing}
          >
            {isProcessing ? (
              <>
                <ActivityIndicator size="large" color="#fff" />
                <Text style={styles.sosText}>Processing...</Text>
              </>
            ) : (
              <>
                <Text style={styles.sosEmoji}>
                  {isRecording ? '🎤' : '🆘'}
                </Text>
                <Text style={styles.sosText}>
                  {isRecording ? `Recording ${recordingTime}s` : 'Emergency Alert'}
                </Text>
              </>
            )}
          </TouchableOpacity>
          <Text style={styles.sosHint}>
            {isProcessing
              ? 'Sending emergency notifications...'
              : isRecording 
              ? 'Speak clearly. Recording in progress...' 
              : 'Tap to activate emergency protocol'}
          </Text>
        </View>

        {/* Quick Info Card */}
        <View style={styles.infoCard}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Location Status</Text>
            <Text style={styles.infoValue}>
              {location ? '✓ Active' : '○ Acquiring...'}
            </Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Emergency Contacts</Text>
            <Text style={styles.infoValue}>
              {sosHistory.length > 0 ? `${sosHistory[0].contactsNotified || 0} configured` : '0 configured'}
            </Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Dormancy Detection</Text>
            <TouchableOpacity onPress={toggleSensorMonitoring}>
              <Text style={[styles.infoValue, sensorMonitoring && styles.infoValueActive]}>
                {sensorMonitoring ? '● Active' : '○ Inactive'}
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Current Location Card */}
        {location && (
          <View style={styles.locationCard}>
            <Text style={styles.locationTitle}>📍 Current Location</Text>
            <Text style={styles.locationAddress}>{location.address}</Text>
            <Text style={styles.locationCoords}>
              {location.latitude.toFixed(6)}, {location.longitude.toFixed(6)}
            </Text>
            <TouchableOpacity 
              style={styles.refreshButton}
              onPress={getCurrentLocationData}
            >
              <Text style={styles.refreshButtonText}>🔄 Refresh</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Recent Activity */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Recent Activity</Text>
          {sosHistory.length === 0 ? (
            <View style={styles.emptyState}>
              <Text style={styles.emptyEmoji}>✨</Text>
              <Text style={styles.emptyText}>No alerts sent yet</Text>
              <Text style={styles.emptySubtext}>Emergency alerts will appear here</Text>
            </View>
          ) : (
            sosHistory.slice(0, 5).map(record => (
              <View key={record.id} style={styles.historyItem}>
                <View style={styles.historyIconContainer}>
                  <Text style={styles.historyIcon}>🚨</Text>
                </View>
                <View style={styles.historyContent}>
                  <Text style={styles.historyTitle}>Emergency Alert Sent</Text>
                  <Text style={styles.historyTime}>
                    {new Date(record.timestamp).toLocaleString()}
                  </Text>
                  <Text style={styles.historyLocation}>
                    📍 {record.location.address}
                  </Text>
                  <Text style={styles.historyContacts}>
                    ✓ {record.contactsNotified} contact(s) notified
                  </Text>
                </View>
                <View style={styles.historyStatus}>
                  <Text style={styles.historyStatusText}>✓ Sent</Text>
                </View>
              </View>
            ))
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

// ============================================
// CONTACTS SCREEN
// ============================================
function ContactsScreen() {
  const [contacts, setContacts] = useState([]);
  const [modalVisible, setModalVisible] = useState(false);
  const [newContact, setNewContact] = useState({ name: '', phone: '', relation: '' });

  useEffect(() => {
    loadContacts();
  }, []);

  const loadContacts = async () => {
    try {
      const stored = await AsyncStorage.getItem('emergencyContacts');
      if (stored) {
        setContacts(JSON.parse(stored));
      }
    } catch (error) {
      console.error('Error loading contacts:', error);
    }
  };

  const saveContacts = async (updatedContacts) => {
    try {
      await AsyncStorage.setItem('emergencyContacts', JSON.stringify(updatedContacts));
      setContacts(updatedContacts);
    } catch (error) {
      console.error('Error saving contacts:', error);
    }
  };

  const addContact = () => {
    if (newContact.name && newContact.phone) {
      const updated = [...contacts, { ...newContact, id: Date.now() }];
      saveContacts(updated);
      setNewContact({ name: '', phone: '', relation: '' });
      setModalVisible(false);
      Alert.alert('Success', 'Emergency contact added successfully!');
    } else {
      Alert.alert('Error', 'Please fill in name and phone number.');
    }
  };

  const deleteContact = (id) => {
    Alert.alert(
      'Remove Contact',
      'Are you sure you want to remove this emergency contact?',
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'Remove', 
          onPress: () => {
            const updated = contacts.filter(c => c.id !== id);
            saveContacts(updated);
          },
          style: 'destructive'
        }
      ]
    );
  };

  const testContact = async (contact) => {
    Alert.alert(
      'Test Contact',
      `Send a test message to ${contact.name}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Send Test',
          onPress: async () => {
            try {
              const location = await LocationService.getCurrentLocation();
              await SMSService.sendEmergencySMS(
                [contact],
                'This is a test message from your emergency contact app.',
                location
              );
              Alert.alert('Success', 'Test message sent!');
            } catch (error) {
              Alert.alert('Error', 'Failed to send test message.');
            }
          }
        }
      ]
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Emergency Contacts</Text>
        <Text style={styles.headerSubtitle}>
          {contacts.length} contact{contacts.length !== 1 ? 's' : ''} configured
        </Text>
      </View>

      <ScrollView style={styles.content}>
        {contacts.length === 0 ? (
          <View style={styles.emptyState}>
            <Text style={styles.emptyEmoji}>👥</Text>
            <Text style={styles.emptyText}>No emergency contacts yet</Text>
            <Text style={styles.emptySubtext}>
              Add trusted contacts who will be notified during emergencies
            </Text>
          </View>
        ) : (
          contacts.map(contact => (
            <View key={contact.id} style={styles.contactCard}>
              <View style={styles.contactAvatar}>
                <Text style={styles.contactAvatarText}>
                  {contact.name.charAt(0).toUpperCase()}
                </Text>
              </View>
              <View style={styles.contactInfo}>
                <Text style={styles.contactName}>{contact.name}</Text>
                <Text style={styles.contactPhone}>{contact.phone}</Text>
                <Text style={styles.contactRelation}>{contact.relation}</Text>
              </View>
              <View style={styles.contactActions}>
                <TouchableOpacity
                  style={styles.testButton}
                  onPress={() => testContact(contact)}
                >
                  <Text style={styles.testButtonText}>Test</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.deleteButton}
                  onPress={() => deleteContact(contact.id)}
                >
                  <Text style={styles.deleteButtonText}>✕</Text>
                </TouchableOpacity>
              </View>
            </View>
          ))
        )}

        <TouchableOpacity
          style={styles.addContactButton}
          onPress={() => setModalVisible(true)}
        >
          <Text style={styles.addContactButtonText}>+ Add Emergency Contact</Text>
        </TouchableOpacity>
      </ScrollView>

      {/* Add Contact Modal */}
      <Modal
        visible={modalVisible}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Add Emergency Contact</Text>
            
            <TextInput
              style={styles.input}
              placeholder="Full Name *"
              value={newContact.name}
              onChangeText={(text) => setNewContact({...newContact, name: text})}
            />
            
            <TextInput
              style={styles.input}
              placeholder="Phone Number *"
              value={newContact.phone}
              keyboardType="phone-pad"
              onChangeText={(text) => setNewContact({...newContact, phone: text})}
            />
            
            <TextInput
              style={styles.input}
              placeholder="Relationship (e.g., Family, Friend, Support Worker)"
              value={newContact.relation}
              onChangeText={(text) => setNewContact({...newContact, relation: text})}
            />

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.modalButtonCancel]}
                onPress={() => setModalVisible(false)}
              >
                <Text style={styles.modalButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.modalButtonAdd]}
                onPress={addContact}
              >
                <Text style={[styles.modalButtonText, styles.modalButtonTextAdd]}>
                  Add Contact
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

// ============================================
// SETTINGS SCREEN
// ============================================
function SettingsScreen() {
  const [stealthMode, setStealthMode] = useState(true);
  const [autoTrigger, setAutoTrigger] = useState(false);
  const [dormancyTime, setDormancyTime] = useState('15');
  const [recordingDuration, setRecordingDuration] = useState('30');

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const settings = await AsyncStorage.getItem('appSettings');
      if (settings) {
        const parsed = JSON.parse(settings);
        setStealthMode(parsed.stealthMode ?? true);
        setAutoTrigger(parsed.autoTrigger ?? false);
        setDormancyTime(parsed.dormancyTime ?? '15');
        setRecordingDuration(parsed.recordingDuration ?? '30');
      }
    } catch (error) {
      console.error('Error loading settings:', error);
    }
  };

  const saveSettings = async (key, value) => {
    try {
      const current = await AsyncStorage.getItem('appSettings');
      const settings = current ? JSON.parse(current) : {};
      settings[key] = value;
      await AsyncStorage.setItem('appSettings', JSON.stringify(settings));
    } catch (error) {
      console.error('Error saving settings:', error);
    }
  };

  const clearAllData = () => {
    Alert.alert(
      'Clear All Data',
      'This will delete all contacts, history, and settings. Are you sure?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear All',
          style: 'destructive',
          onPress: async () => {
            await AsyncStorage.clear();
            Alert.alert('Success', 'All data cleared. App will restart.');
          }
        }
      ]
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Settings</Text>
        <Text style={styles.headerSubtitle}>Configure app preferences</Text>
      </View>

      <ScrollView style={styles.content}>
        <View style={styles.settingSection}>
          <Text style={styles.settingSectionTitle}>Privacy & Security</Text>
          
          <View style={styles.settingItem}>
            <View style={styles.settingInfo}>
              <Text style={styles.settingLabel}>Stealth Mode</Text>
              <Text style={styles.settingDescription}>
                App appears as "Weather App" with neutral icon
              </Text>
            </View>
            <TouchableOpacity
              style={[styles.toggle, stealthMode && styles.toggleActive]}
              onPress={() => {
                setStealthMode(!stealthMode);
                saveSettings('stealthMode', !stealthMode);
              }}
            >
              <View style={[styles.toggleThumb, stealthMode && styles.toggleThumbActive]} />
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.settingSection}>
          <Text style={styles.settingSectionTitle}>Emergency Settings</Text>
          
          <View style={styles.settingItem}>
            <View style={styles.settingInfo}>
              <Text style={styles.settingLabel}>Recording Duration</Text>
              <Text style={styles.settingDescription}>
                Seconds of audio to record
              </Text>
            </View>
            <TextInput
              style={styles.settingInput}
              value={recordingDuration}
              onChangeText={(text) => {
                setRecordingDuration(text);
                saveSettings('recordingDuration', text);
              }}
              keyboardType="number-pad"
            />
          </View>

          <View style={styles.settingItem}>
            <View style={styles.settingInfo}>
              <Text style={styles.settingLabel}>Auto-Trigger SOS</Text>
              <Text style={styles.settingDescription}>
                Activate alert if no movement detected
              </Text>
            </View>
            <TouchableOpacity
              style={[styles.toggle, autoTrigger && styles.toggleActive]}
              onPress={() => {
                setAutoTrigger(!autoTrigger);
                saveSettings('autoTrigger', !autoTrigger);
              }}
            >
              <View style={[styles.toggleThumb, autoTrigger && styles.toggleThumbActive]} />
            </TouchableOpacity>
          </View>

          <View style={styles.settingItem}>
            <View style={styles.settingInfo}>
              <Text style={styles.settingLabel}>Dormancy Threshold</Text>
              <Text style={styles.settingDescription}>
                Minutes of inactivity before alert
              </Text>
            </View>
            <TextInput
              style={styles.settingInput}
              value={dormancyTime}
              onChangeText={(text) => {
                setDormancyTime(text);
                saveSettings('dormancyTime', text);
              }}
              keyboardType="number-pad"
            />
          </View>
        </View>

        <View style={styles.settingSection}>
          <Text style={styles.settingSectionTitle}>About</Text>
          
          <View style={styles.infoItem}>
            <Text style={styles.infoItemLabel}>Version</Text>
            <Text style={styles.infoItemValue}>1.0.0 (MVP)</Text>
          </View>
          
          <View style={styles.infoItem}>
            <Text style={styles.infoItemLabel}>Build</Text>
            <Text style={styles.infoItemValue}>Production</Text>
          </View>
        </View>

        <TouchableOpacity 
          style={styles.dangerButton}
          onPress={clearAllData}
        >
          <Text style={styles.dangerButtonText}>Clear All Data</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

// ============================================
// MAIN APP COMPONENT
// ============================================
export default function App() {
  return (
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={{
          headerShown: false,
          tabBarStyle: styles.tabBar,
          tabBarActiveTintColor: '#6366f1',
          tabBarInactiveTintColor: '#94a3b8',
        }}
      >
        <Tab.Screen 
          name="Home" 
          component={HomeScreen}
          options={{ tabBarIcon: HomeIcon }}
        />
        <Tab.Screen 
          name="Contacts" 
          component={ContactsScreen}
          options={{ tabBarIcon: ContactsIcon }}
        />
        <Tab.Screen 
          name="Settings" 
          component={SettingsScreen}
          options={{ tabBarIcon: SettingsIcon }}
        />
      </Tab.Navigator>
    </NavigationContainer>
  );
}

// ============================================
// STYLES
// ============================================
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  header: {
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e2e8f0',
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#1e293b',
    marginBottom: 4,
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#64748b',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  
  // SOS Button
  sosContainer: {
    alignItems: 'center',
    marginVertical: 30,
  },
  sosButton: {
    width: 200,
    height: 200,
    borderRadius: 100,
    backgroundColor: '#ef4444',
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 8,
    shadowColor: '#ef4444',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
  sosButtonActive: {
    backgroundColor: '#dc2626',
  },
  sosEmoji: {
    fontSize: 64,
    marginBottom: 8,
  },
  sosText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#fff',
  },
  sosHint: {
    marginTop: 16,
    fontSize: 14,
    color: '#64748b',
    textAlign: 'center',
    paddingHorizontal: 20,
  },

  // Info Card
  infoCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    elevation: 2,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
  },
  infoLabel: {
    fontSize: 14,
    color: '#64748b',
  },
  infoValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1e293b',
  },
  infoValueActive: {
    color: '#10b981',
  },

  // Location Card
  locationCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    elevation: 2,
  },
  locationTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 8,
  },
  locationAddress: {
    fontSize: 14,
    color: '#64748b',
    marginBottom: 4,
  },
  locationCoords: {
    fontSize: 12,
    color: '#94a3b8',
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
  },
  refreshButton: {
    marginTop: 12,
    paddingVertical: 8,
    paddingHorizontal: 16,
    backgroundColor: '#f1f5f9',
    borderRadius: 8,
    alignSelf: 'flex-start',
  },
  refreshButtonText: {
    fontSize: 14,
    color: '#6366f1',
    fontWeight: '600',
  },

  // Section
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 12,
  },

  // History Item
  historyItem: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    elevation: 2,
  },
  historyIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#fef2f2',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  historyIcon: {
    fontSize: 24,
  },
  historyContent: {
    flex: 1,
  },
  historyTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 4,
  },
  historyTime: {
    fontSize: 12,
    color: '#64748b',
    marginBottom: 4,
  },
  historyLocation: {
    fontSize: 12,
    color: '#64748b',
    marginBottom: 2,
  },
  historyContacts: {
    fontSize: 12,
    color: '#10b981',
  },
  historyStatus: {
    justifyContent: 'center',
  },
  historyStatusText: {
    fontSize: 12,
    color: '#10b981',
    fontWeight: '600',
  },

  // Empty State
  emptyState: {
    alignItems: 'center',
    paddingVertical: 40,
    backgroundColor: '#fff',
    borderRadius: 12,
    marginBottom: 12,
  },
  emptyEmoji: {
    fontSize: 48,
    marginBottom: 12,
  },
  emptyText: {
    fontSize: 16,
    color: '#1e293b',
    fontWeight: '600',
    marginBottom: 4,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#94a3b8',
    textAlign: 'center',
    paddingHorizontal: 40,
  },

  // Contact Card
  contactCard: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    elevation: 2,
    alignItems: 'center',
  },
  contactAvatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#6366f1',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  contactAvatarText: {
    fontSize: 24,
    fontWeight: '600',
    color: '#fff',
  },
  contactInfo: {
    flex: 1,
  },
  contactName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 4,
  },
  contactPhone: {
    fontSize: 14,
    color: '#64748b',
    marginBottom: 2,
  },
  contactRelation: {
    fontSize: 12,
    color: '#94a3b8',
  },
  contactActions: {
    flexDirection: 'row',
    gap: 8,
  },
  testButton: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    backgroundColor: '#f1f5f9',
    borderRadius: 8,
  },
  testButtonText: {
    fontSize: 12,
    color: '#6366f1',
    fontWeight: '600',
  },
  deleteButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#fef2f2',
    alignItems: 'center',
    justifyContent: 'center',
  },
  deleteButtonText: {
    fontSize: 18,
    color: '#ef4444',
  },

  // Add Contact Button
  addContactButton: {
    backgroundColor: '#6366f1',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    marginTop: 8,
  },
  addContactButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#fff',
  },

  // Modal
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#fff',
    borderRadius: 20,
    padding: 24,
    width: '85%',
    maxWidth: 400,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1e293b',
    marginBottom: 20,
  },
  input: {
    backgroundColor: '#f8fafc',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#e2e8f0',
  },
  modalButtons: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 8,
  },
  modalButton: {
    flex: 1,
    padding: 14,
    borderRadius: 8,
    alignItems: 'center',
  },
  modalButtonCancel: {
    backgroundColor: '#f1f5f9',
  },
  modalButtonAdd: {
    backgroundColor: '#6366f1',
  },
  modalButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#64748b',
  },
  modalButtonTextAdd: {
    color: '#fff',
  },

  // Settings
  settingSection: {
    marginBottom: 24,
  },
  settingSectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 12,
  },
  settingItem: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 8,
    alignItems: 'center',
    elevation: 2,
  },
  settingInfo: {
    flex: 1,
  },
  settingLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 4,
  },
  settingDescription: {
    fontSize: 13,
    color: '#64748b',
  },
  toggle: {
    width: 51,
    height: 31,
    borderRadius: 16,
    backgroundColor: '#cbd5e1',
    padding: 2,
    justifyContent: 'center',
  },
  toggleActive: {
    backgroundColor: '#6366f1',
  },
  toggleThumb: {
    width: 27,
    height: 27,
    borderRadius: 14,
    backgroundColor: '#fff',
  },
  toggleThumbActive: {
    alignSelf: 'flex-end',
  },
  settingInput: {
    backgroundColor: '#f8fafc',
    borderRadius: 8,
    padding: 8,
    fontSize: 16,
    width: 60,
    textAlign: 'center',
    borderWidth: 1,
    borderColor: '#e2e8f0',
  },

  // Info Item
  infoItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
  },
  infoItemLabel: {
    fontSize: 14,
    color: '#64748b',
  },
  infoItemValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1e293b',
  },

  // Danger Button
  dangerButton: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#ef4444',
    marginTop: 16,
    marginBottom: 40,
  },
  dangerButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ef4444',
  },

  // Tab Bar
  tabBar: {
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e2e8f0',
    height: 60,
    paddingBottom: 8,
    paddingTop: 8,
  },
  tabIcon: {
    fontSize: 24,
  },
});