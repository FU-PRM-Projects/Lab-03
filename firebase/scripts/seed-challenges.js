// Seeds the read-only `challenges` catalog (deviation D-10) from
// seed/challenges.json.
//
// Emulator:      npm run seed:emulator   (needs `npm run emulators` running)
// Real project:  set GOOGLE_APPLICATION_CREDENTIALS to a service-account key
//                kept OUTSIDE the repo, then `npm run seed -- <project-id>`.
const fs = require('node:fs');
const path = require('node:path');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const projectId = process.argv[2] || 'prm393-not-lab3';
const emulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
if (!emulator && projectId.startsWith('demo-')) {
  console.error('demo-* projects only exist on the emulator; set FIRESTORE_EMULATOR_HOST.');
  process.exit(1);
}

initializeApp(emulator ? { projectId } : { projectId, credential: applicationDefault() });
const db = getFirestore();

async function main() {
  const cards = JSON.parse(
    fs.readFileSync(path.join(__dirname, '../seed/challenges.json'), 'utf8'),
  );
  const batch = db.batch();
  for (const { id, ...card } of cards) {
    batch.set(db.collection('challenges').doc(id), card);
  }
  await batch.commit();
  console.log(`Seeded ${cards.length} challenges into ${projectId}${emulator ? ' (emulator)' : ''}.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
