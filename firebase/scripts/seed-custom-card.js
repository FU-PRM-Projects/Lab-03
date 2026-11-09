// Emulator only: gives a user one self-made challenge card, so the app's
// "Gửi cho mọi người" button can be tried even while Remote Config
// `custom_challenges_enabled` hides the add button.
//   npm run seed:custom-card -- someone@example.test
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Emulator only: set FIRESTORE_EMULATOR_HOST.');
  process.exit(1);
}
const [email, title = 'Rủ một bạn cùng lớp đi bộ 10 phút'] = process.argv.slice(2);
if (!email) {
  console.error('Usage: seed-custom-card.js <user-email> [title]');
  process.exit(1);
}
initializeApp({ projectId: 'prm393-not-lab3' });

async function main() {
  const user = await getAuth().getUserByEmail(email);
  const ref = getFirestore().collection(`users/${user.uid}/customChallenges`).doc();
  await ref.set({
    topic: 'van_dong',
    title,
    minutes: 10,
    tip: 'Hẹn giờ cụ thể trước',
    createdAt: FieldValue.serverTimestamp(),
  });
  console.log(`Added custom card ${ref.id} for ${email}.`);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
