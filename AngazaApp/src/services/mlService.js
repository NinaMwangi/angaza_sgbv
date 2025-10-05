// import * as tf from '@tensorflow/tfjs';
// import '@tensorflow/tfjs-react-native';

// let model = null;

// export const loadDormancyModel = async () => {
//   try {
//     await tf.ready();
//     // Load your pre-trained model
//     model = await tf.loadLayersModel('https://yourserver.com/model.json');
//     console.log('ML Model loaded');
//     return true;
//   } catch (error) {
//     console.error('Model loading error:', error);
//     return false;
//   }
// };

// export const predictDormancy = async (sensorData) => {
//   if (!model) {
//     console.error('Model not loaded');
//     return null;
//   }

//   try {
//     const inputTensor = tf.tensor2d([sensorData]);
//     const prediction = await model.predict(inputTensor);
//     const result = await prediction.data();
    
//     inputTensor.dispose();
//     prediction.dispose();
    
//     return result[0];
//   } catch (error) {
//     console.error('Prediction error:', error);
//     return null;
//   }
// };

// no ml required mvp
// Simple rule-based detection (Good for MVP - no ML required)
export const detectDormancySimple = (sensorReadings, timeWindow = 15 * 60 * 1000) => {
  const MOVEMENT_THRESHOLD = 0.2;
  
  const recentReadings = sensorReadings.filter(
    reading => Date.now() - reading.timestamp < timeWindow
  );
  
  if (recentReadings.length === 0) {
    return {
      isDormant: true,
      timeSinceMovement: timeWindow,
      confidence: 1,
    };
  }
  
  const hasMovement = recentReadings.some(
    reading => 
      reading.acceleration > MOVEMENT_THRESHOLD ||
      reading.rotation > MOVEMENT_THRESHOLD
  );
  
  const timeSinceLastMovement = hasMovement 
    ? 0 
    : Date.now() - recentReadings[recentReadings.length - 1].timestamp;
  
  return {
    isDormant: timeSinceLastMovement > timeWindow,
    timeSinceMovement: timeSinceLastMovement,
    confidence: hasMovement ? 0 : 1,
  };
};
