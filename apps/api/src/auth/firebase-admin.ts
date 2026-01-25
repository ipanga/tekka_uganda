import * as admin from 'firebase-admin';
import { ConfigService } from '@nestjs/config';

let firebaseApp: admin.app.App | null = null;

export function initializeFirebase(
  configService: ConfigService,
): admin.app.App {
  if (firebaseApp) {
    return firebaseApp;
  }

  const projectId = configService.get<string>('FIREBASE_PROJECT_ID');
  const privateKey = configService
    .get<string>('FIREBASE_PRIVATE_KEY')
    ?.replace(/\\n/g, '\n');
  const clientEmail = configService.get<string>('FIREBASE_CLIENT_EMAIL');

  if (!projectId || !privateKey || !clientEmail) {
    throw new Error(
      'Firebase configuration is incomplete. Check environment variables.',
    );
  }

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      privateKey,
      clientEmail,
    }),
  });

  return firebaseApp;
}

export function getFirebaseAuth(): admin.auth.Auth {
  if (!firebaseApp) {
    throw new Error(
      'Firebase has not been initialized. Call initializeFirebase first.',
    );
  }
  return firebaseApp.auth();
}

export function getFirebaseMessaging(): admin.messaging.Messaging {
  if (!firebaseApp) {
    throw new Error(
      'Firebase has not been initialized. Call initializeFirebase first.',
    );
  }
  return firebaseApp.messaging();
}
