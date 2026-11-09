// Emulator only: adds pending card suggestions from a user account so the web
// admin review queue has something to show.
//   npm run seed:submissions -- someone@example.test
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Emulator only: set FIRESTORE_EMULATOR_HOST.');
  process.exit(1);
}
const [email] = process.argv.slice(2);
if (!email) {
  console.error('Usage: seed-submissions.js <user-email>');
  process.exit(1);
}
initializeApp({ projectId: 'prm393-not-lab3' });

const cards = [
  { topic: 'van_dong', title: 'Đi cầu thang thay thang máy', minutes: 5, tip: 'Từ tầng 3 trở xuống' },
  { topic: 'dung_cam', title: 'Hỏi thủ thư một cuốn sách hay', minutes: 3, tip: 'Hỏi ngắn, cảm ơn khi xong' },
  { topic: 'van_dong', title: 'Giãn cơ 5 phút giữa hai tiết học', minutes: 5 },
];

async function main() {
  const user = await getAuth().getUserByEmail(email);
  const db = getFirestore();
  const batch = db.batch();
  for (const card of cards) {
    batch.set(db.collection('challengeSubmissions').doc(), {
      uid: user.uid,
      ...card,
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`Added ${cards.length} pending submissions from ${email}.`);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
