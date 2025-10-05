import { accelerometer, gyroscope, setUpdateIntervalForType, SensorTypes } from 'react-native-sensors';

let accelerometerSubscription = null;
let gyroscopeSubscription = null;
let lastMovementTime = Date.now();
let dormancyCallback = null;
let dormancyCheckInterval = null;

const MOVEMENT_THRESHOLD = 0.15;
const DORMANCY_TIME = 15 * 60 * 1000; // 15 minutes

setUpdateIntervalForType(SensorTypes.accelerometer, 1000);
setUpdateIntervalForType(SensorTypes.gyroscope, 1000);

export const startSensorMonitoring = (onDormancyDetected) => {
  dormancyCallback = onDormancyDetected;
  lastMovementTime = Date.now();

  // Monitor accelerometer
  accelerometerSubscription = accelerometer.subscribe(({ x, y, z }) => {
    const totalAcceleration = Math.sqrt(x * x + y * y + z * z);
    
    if (Math.abs(totalAcceleration - 9.8) > MOVEMENT_THRESHOLD) {
      lastMovementTime = Date.now();
    }
  });

  // Monitor gyroscope
  gyroscopeSubscription = gyroscope.subscribe(({ x, y, z }) => {
    const totalRotation = Math.sqrt(x * x + y * y + z * z);
    
    if (totalRotation > MOVEMENT_THRESHOLD) {
      lastMovementTime = Date.now();
    }
  });

  // Check for dormancy every 30 seconds
  dormancyCheckInterval = setInterval(() => {
    const timeSinceLastMovement = Date.now() - lastMovementTime;
    
    if (timeSinceLastMovement > DORMANCY_TIME) {
      console.log('Dormancy detected!');
      if (dormancyCallback) {
        dormancyCallback(timeSinceLastMovement);
      }
    }
  }, 30000);

  console.log('Sensor monitoring started');
  return dormancyCheckInterval;
};

export const stopSensorMonitoring = () => {
  if (accelerometerSubscription) {
    accelerometerSubscription.unsubscribe();
    accelerometerSubscription = null;
  }
  if (gyroscopeSubscription) {
    gyroscopeSubscription.unsubscribe();
    gyroscopeSubscription = null;
  }
  if (dormancyCheckInterval) {
    clearInterval(dormancyCheckInterval);
    dormancyCheckInterval = null;
  }
  console.log('Sensor monitoring stopped');
};

export const getLastMovementTime = () => {
  return lastMovementTime;
};

export const getTimeSinceLastMovement = () => {
  return Date.now() - lastMovementTime;
};
