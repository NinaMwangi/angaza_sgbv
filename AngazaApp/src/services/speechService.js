const GOOGLE_CLOUD_API_KEY = 'YOUR_API_KEY_HERE';

export const transcribeAudioGoogle = async (audioFilePath) => {
  try {
    const RNFS = require('react-native-fs');
    const audioBase64 = await RNFS.readFile(audioFilePath, 'base64');

    const response = await fetch(
      `https://speech.googleapis.com/v1/speech:recognize?key=${GOOGLE_CLOUD_API_KEY}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          config: {
            encoding: 'AMR_WB',
            sampleRateHertz: 16000,
            languageCode: 'en-US',
            enableAutomaticPunctuation: true,
          },
          audio: {
            content: audioBase64,
          },
        }),
      }
    );

    const data = await response.json();
    
    if (data.results && data.results.length > 0) {
      const transcription = data.results
        .map(result => result.alternatives[0].transcript)
        .join(' ');
      return transcription;
    }
    
    return 'Unable to transcribe audio';
  } catch (error) {
    console.error('Transcription error:', error);
    return 'Audio recorded but transcription unavailable';
  }
};

// Option 2: Using React Native Voice (Device built-in)
import Voice from '@react-native-voice/voice';

export const startVoiceRecognition = () => {
  return new Promise((resolve, reject) => {
    Voice.onSpeechResults = (e) => {
      resolve(e.value[0]);
    };

    Voice.onSpeechError = (e) => {
      reject(e.error);
    };

    Voice.start('en-US');
  });
};

export const stopVoiceRecognition = async () => {
  try {
    await Voice.stop();
    await Voice.destroy();
  } catch (error) {
    console.error('Voice recognition stop error:', error);
  }
};