# Survivor Safety App (Angaza)

A React Native mobile application designed to provide emergency safety features for survivors of domestic violence and vulnerable individuals. The app includes SOS alerts, location tracking, sensor-based dormancy detection, and emergency contact notifications.

### Demo: https://drive.google.com/file/d/1VWWi9rlBzcHjzwVN6BTvQtbNG7moLVnt/view?usp=share_link

##  Features

### Core Features (MVP)
- **Emergency SOS Button** - One-tap emergency alert with 30-second audio recording
- **Real-time Location Tracking** - GPS coordinates with reverse geocoding
- **SMS Emergency Alerts** - Automatic notifications to multiple emergency contacts
- **Sensor-Based Dormancy Detection** - Accelerometer/Gyroscope monitoring for inactivity
- **Stealth Mode** - Disguised as "Weather App" for privacy and safety
- **Emergency Contact Management** - Add, edit, and test emergency contacts
- **SOS History** - Track all emergency alerts sent
- **Customizable Settings** - Configure recording duration, dormancy thresholds, etc.

### Advanced Features (Planned)
- Speech-to-Text transcription
- WhatsApp integration
- Hardware button support
- NGO/Social worker dashboard
- ML-based threat detection
- Background monitoring service

##  Architecture

```
AngazaApp/
├── android/                      # Android native code
│   └── app/src/main/
│       └── AndroidManifest.xml   # Permissions configuration
├── src/
│   └── services/
│       ├── audioService.js       # Audio recording functionality
│       ├── locationService.js    # GPS & geocoding
│       ├── sensorService.js      # Accelerometer/Gyroscope monitoring
│       ├── smsService.js         # SMS emergency alerts
│       ├── speechService.js      # Speech-to-text (optional)
│       └── mlService.js          # ML models (optional)
├── App.js                        # Main application entry point
├── package.json                  # Dependencies
└── README.md                     # This file
```

##  Getting Started

### Prerequisites

- **Node.js** (v18 or later) - [Download](https://nodejs.org/)
- **React Native CLI** - `npm install -g react-native-cli`
- **Java Development Kit (JDK 11)** - [Download](https://adoptium.net/)
- **Android Studio** - [Download](https://developer.android.com/studio)
  - Android SDK (API 33 or higher)
  - Android Virtual Device (AVD) or physical device

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/angaza-app.git
   cd angaza-app
   ```

2. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```


3. **Configure Android permissions:**
   
   Ensure `android/app/src/main/AndroidManifest.xml` includes:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.SEND_SMS" />
   <uses-permission android:name="android.permission.READ_SMS" />
   ```

### Running the App

1. **Start Metro bundler:**
   ```bash
   npm start
   ```

2. **Run on Android:**
   ```bash
   # Start emulator
   emulator @Pixel_7_Pro_API_33
   
   # Build and run
   npx react-native run-android
   ```


## 📦 Dependencies

### Core Dependencies
```json
{
  "react": "18.2.0",
  "react-native": "0.72.0",
  "@react-navigation/native": "^6.1.7",
  "@react-navigation/bottom-tabs": "^6.5.8",
  "react-native-screens": "^3.22.0",
  "react-native-safe-area-context": "^4.6.3",
  "@react-native-async-storage/async-storage": "^1.19.0"
}
```

### Service Dependencies
```json
{
  "@react-native-community/geolocation": "^3.0.0",
  "react-native-sensors": "^7.3.6",
  "react-native-sms": "^1.9.0",
  "react-native-audio-recorder-player": "^3.5.3"
}
```

### Optional Dependencies
```json
{
  "react-native-fs": "^2.20.0",
  "@react-native-voice/voice": "^3.2.4",
  "@react-native-firebase/app": "^18.0.0",
  "@react-native-firebase/firestore": "^18.0.0"
}
```

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# API Keys 
GOOGLE_CLOUD_API_KEY=your_api_key_here
FIREBASE_API_KEY=your_firebase_key_here

# App Configuration
APP_NAME=Weather App
RECORDING_DURATION=30
DORMANCY_THRESHOLD=15
```

### App Settings

Configure app behavior in Settings screen:
- **Stealth Mode**: Enable/disable disguise mode
- **Recording Duration**: 15-60 seconds
- **Dormancy Threshold**: 30-90 minutes
- **Auto-Trigger**: Enable automatic SOS on dormancy detection

## Usage

### First-Time Setup

1. **Grant Permissions**: On first launch, grant all requested permissions
2. **Add Emergency Contacts**: 
   - Navigate to "Contacts" tab
   - Tap "+ Add Emergency Contact"
   - Enter name, phone number, and relationship
   - Save contact
3. **Test Contacts**: Use "Test" button to verify SMS functionality
4. **Configure Settings**: Adjust thresholds and preferences

### Triggering an SOS Alert

**Method 1: Manual Trigger**
1. Tap the large red SOS button on home screen
2. Confirm the alert
3. Speak clearly for 30 seconds (audio will be recorded)
4. Wait for processing and SMS delivery confirmation

**Method 2: Dormancy Detection**
1. Enable "Dormancy Detection" in settings
2. Phone will monitor for movement
3. After configured inactivity period, alert will prompt
4. Option to cancel or send SOS automatically

### Managing Emergency Contacts

- **Add Contact**: Contacts tab → "+ Add Emergency Contact"
- **Test Contact**: Tap "Test" button on contact card
- **Remove Contact**: Tap "✕" button → Confirm removal
- **Minimum Required**: At least 1 contact (recommended: 3+)

### Viewing History

- Navigate to Home tab
- Scroll to "Recent Activity" section
- View last 5 SOS alerts with:
  - Timestamp
  - Location
  - Number of contacts notified
  - Status (Sent/Failed)

##  Development

### Project Structure

```javascript
// App.js - Main entry point with navigation
export default function App() {
  return (
    <NavigationContainer>
      <Tab.Navigator>
        <Tab.Screen name="Home" component={HomeScreen} />
        <Tab.Screen name="Contacts" component={ContactsScreen} />
        <Tab.Screen name="Settings" component={SettingsScreen} />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
```

### Key Services

#### Audio Service (`src/services/audioService.js`)
```javascript
import AudioRecorderPlayer from 'react-native-audio-recorder-player';

export const startRecording = async () => {
  // Start 30-second audio recording
};

export const stopRecording = async () => {
  // Stop and save recording
};
```

#### Location Service (`src/services/locationService.js`)
```javascript
import Geolocation from '@react-native-community/geolocation';

export const getCurrentLocation = () => {
  // Get GPS coordinates
};

export const getAddressFromCoordinates = async (lat, lng) => {
  // Reverse geocoding
};
```

#### Sensor Service (`src/services/sensorService.js`)
```javascript
import { accelerometer, gyroscope } from 'react-native-sensors';

export const startSensorMonitoring = (callback) => {
  // Monitor device movement
};

export const stopSensorMonitoring = () => {
  // Stop monitoring
};
```

#### SMS Service (`src/services/smsService.js`)
```javascript
import SendSMS from 'react-native-sms';

export const sendEmergencySMS = async (contacts, message, location) => {
  // Send SMS to all emergency contacts
};
```
