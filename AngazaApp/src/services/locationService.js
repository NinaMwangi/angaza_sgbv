import Geolocation from '@react-native-community/geolocation';

export const getCurrentLocation = () => {
  return new Promise((resolve, reject) => {
    Geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        resolve({
          latitude,
          longitude,
          accuracy: position.coords.accuracy,
          timestamp: position.timestamp,
        });
      },
      (error) => {
        console.error('Location error:', error);
        reject(error);
      },
      {
        enableHighAccuracy: true,
        timeout: 15000,
        maximumAge: 10000,
      }
    );
  });
};

export const watchLocation = (callback) => {
  return Geolocation.watchPosition(
    (position) => {
      callback({
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
        accuracy: position.coords.accuracy,
      });
    },
    (error) => {
      console.error('Location watch error:', error);
    },
    {
      enableHighAccuracy: true,
      distanceFilter: 10,
      interval: 5000,
    }
  );
};

export const stopWatchingLocation = (watchId) => {
  Geolocation.clearWatch(watchId);
};

export const getAddressFromCoordinates = async (latitude, longitude) => {
  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=18&addressdetails=1`,
      {
        headers: {
          'User-Agent': 'SurvivorSafetyApp/1.0'
        }
      }
    );
    const data = await response.json();
    return data.display_name || `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
  } catch (error) {
    console.error('Geocoding error:', error);
    return `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
  }
};