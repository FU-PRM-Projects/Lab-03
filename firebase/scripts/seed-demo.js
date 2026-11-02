// Seeds demo notes for one account so S02, S05, S11 have something to show:
// ~60 days of mood-tagged wins (energy chart, mood calendar), a few
// memorable "first time" wins (S02 "Nhớ lại lần này nhé") and their groups.
//
// Emulator only. Sign up in the app first, then (with `npm run emulators`
// running):
//
//   npm run seed:demo -- <email>
//
// Dates are relative to today and document ids are fixed, so running it again
// refreshes the same notes instead of adding more.
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

const projectId = 'demo-prm393';
const email = process.argv[2];
if (!email) {
  console.error('Usage: npm run seed:demo -- <email>');
  process.exit(1);
}
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Demo data is for the emulator only; run it with `npm run seed:demo`.');
  process.exit(1);
}

initializeApp({ projectId });
const db = getFirestore();

const MOODS = ['roi', 'met', 'binh_thuong', 'on', 'vui']; // score 1..5
const DAILY = [
  'Đi bộ 15 phút',
  'Dọn góc học tập',
  'Hỏi bạn bài khó',
  'Ngủ trước 12h',
  'Uống đủ nước',
  'Đọc 10 trang sách',
];

// [id, title, body, mood, days ago, group]
const WINS = [
  ['win-thuyet-trinh', 'Thuyết trình trước lớp dù run',
    'Run lắm nhưng nói xong thấy nhẹ cả người.', 'vui', 11, 'len-tieng-trong-nhom'],
  ['win-hoi-thay', 'Hỏi thầy câu mình không hiểu',
    'Thầy giảng lại rất kỹ, hoá ra hỏi không đáng sợ.', 'on', 15, null],
  ['win-xe-buyt', 'Lần đầu tự đi xe buýt lên trường',
    'Lên nhầm chiều một lần nhưng vẫn tới kịp giờ.', 'vui', 18, 'tu-di-noi-moi'],
];

// Must match FirstGroups.system in lib/models/first_group.dart.
const GROUPS = {
  'len-tieng-trong-nhom': { name: 'Lên tiếng trong nhóm', idea: 'chien_thang' },
  'tu-di-noi-moi': { name: 'Tự đi nơi mới', idea: 'van_dong' },
};

/** 20:30 local time, `daysAgo` days before today. */
function eveningOf(daysAgo) {
  const day = new Date();
  day.setDate(day.getDate() - daysAgo);
  day.setHours(20, 30, 0, 0);
  return Timestamp.fromDate(day);
}

async function main() {
  const user = await getAuth().getUserByEmail(email).catch(() => null);
  if (!user) {
    console.error(`No account for ${email} on the emulator. Sign up in the app first.`);
    process.exit(1);
  }
  const notes = db.collection('users').doc(user.uid).collection('notes');
  const groups = db.collection('users').doc(user.uid).collection('groups');
  const batch = db.batch();

  let energy = 0;
  for (let back = 1; back < 60; back++) {
    if (back % 5 === 0) continue; // skip a few days, like a real diary
    // A gentle wave around 3.5, a little higher over the last 30 days.
    const score = 3.2 + 1.3 * Math.sin(back / 1.4) + 0.6 * Math.sin(back / 3.7)
      + (back <= 30 ? 0.4 : 0);
    batch.set(notes.doc(`energy-${back}`), {
      type: 'chien_thang',
      title: DAILY[back % DAILY.length],
      mood: MOODS[Math.max(0, Math.min(4, Math.round(score) - 1))],
      createdAt: eveningOf(back),
    });
    energy++;
  }

  for (const [id, title, body, mood, daysAgo, groupId] of WINS) {
    const createdAt = eveningOf(daysAgo);
    batch.set(notes.doc(id), {
      type: 'chien_thang',
      title,
      body,
      mood,
      createdAt,
      ...(groupId ? { groupId, isFirst: true } : {}),
    });
    if (groupId) {
      batch.set(groups.doc(groupId), {
        ...GROUPS[groupId],
        source: 'system',
        noteCount: 1,
        firstNoteId: id,
        firstNoteTitle: title,
        firstAt: createdAt,
        lastAt: createdAt,
        createdAt,
      });
    }
  }

  await batch.commit();
  console.log(`Seeded ${energy} daily notes, ${WINS.length} memorable wins and `
    + `${Object.keys(GROUPS).length} groups for ${email}.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
