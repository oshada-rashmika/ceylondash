import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  try {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY environment variable is not set');
    }
    const serviceAccount = JSON.parse(serviceAccountJson);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin initialized successfully.');
  } catch (error) {
    console.error('Firebase Admin initialization error', error);
  }
}

export const db = admin.firestore();
export default admin;
