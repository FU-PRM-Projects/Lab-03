// Sets users/{uid}.role for an account found by e-mail. This is how the first
// admin is created (rules only let an admin change roles, so the very first
// one must be set with admin rights: here or in the Firebase console).
//
// Emulator:      npm run role:emulator -- someone@example.test admin
// Real project:  set GOOGLE_APPLICATION_CREDENTIALS to a service-account key
//                kept OUTSIDE the repo, then
//                npm run role -- someone@gmail.com admin [project-id]
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const [email, role, projectId = 'prm393-not-lab3'] = process.argv.slice(2);
if (!email || !['user', 'staff', 'admin'].includes(role)) {
  console.error('Usage: set-role.js <email> <user|staff|admin> [project-id]');
  process.exit(1);
}
const emulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
initializeApp(emulator ? { projectId } : { projectId, credential: applicationDefault() });

async function main() {
  const user = await getAuth().getUserByEmail(email);
  const doc = getFirestore().collection('users').doc(user.uid);
  if ((await doc.get()).exists) {
    await doc.update({ role, email });
  } else {
    await doc.set({
      role,
      displayName: user.displayName || '',
      email,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  console.log(`${email} (${user.uid}) is now ${role}${emulator ? ' on the emulator' : ''}.`);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
