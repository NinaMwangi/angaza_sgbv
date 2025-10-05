import SendSMS from 'react-native-sms';

export const sendEmergencySMS = async (contacts, message, location) => {
  const phoneNumbers = contacts.map(contact => contact.phone);
  
  const fullMessage = `
🆘 EMERGENCY ALERT 🆘

${message}

📍 Location: ${location.address || `${location.latitude}, ${location.longitude}`}

🗺️ Google Maps: https://maps.google.com/?q=${location.latitude},${location.longitude}

⏰ Time: ${new Date().toLocaleString()}

This is an automated emergency message.
  `.trim();

  try {
    await SendSMS.send({
      body: fullMessage,
      recipients: phoneNumbers,
      successTypes: ['sent', 'queued'],
      allowAndroidSendWithoutReadPermission: true,
    });
    
    console.log('SMS sent to:', phoneNumbers);
    return true;
  } catch (error) {
    console.error('SMS error:', error);
    throw new Error('Failed to send SMS. Please check SMS permissions.');
  }
};

export const sendTestSMS = async (contact, location) => {
  const testMessage = `
Hello ${contact.name},

This is a TEST message from your emergency contact app.

If you receive this, you are successfully configured as an emergency contact.

📍 Test Location: ${location.address || `${location.latitude}, ${location.longitude}`}

No action is needed. This is only a test.

— Emergency Contact System
  `.trim();

  try {
    await SendSMS.send({
      body: testMessage,
      recipients: [contact.phone],
      successTypes: ['sent', 'queued'],
      allowAndroidSendWithoutReadPermission: true,
    });
    
    return true;
  } catch (error) {
    console.error('Test SMS error:', error);
    throw error;
  }
};
