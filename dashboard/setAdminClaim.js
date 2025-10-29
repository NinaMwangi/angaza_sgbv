const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // path to JSON

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  //projectId: 'your-project-id',
});

const uid = 'eF1lslBY65fKaheMgvb8WF07eqt1';
admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => console.log('✅ set'))
  .catch(console.error);
