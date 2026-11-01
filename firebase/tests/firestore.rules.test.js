const { test, before, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, Timestamp } = require('firebase/firestore');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-prm393',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '../firestore.rules'), 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/alice'), { role: 'user' });
    await setDoc(doc(db, 'users/root'), { role: 'admin' });
  });
});
after(() => env.cleanup());

test('R-01 user cannot change own role', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(updateDoc(doc(db, 'users/alice'), { role: 'admin' }));
});
test('R-02 admin can change a role', async () => {
  const db = env.authenticatedContext('root').firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/alice'), { role: 'staff' }));
});
test('R-03 user reads own profile; unauthenticated denied', async () => {
  await assertSucceeds(getDoc(doc(env.authenticatedContext('alice').firestore(), 'users/alice')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice')));
});
test('R-04 unknown collection denied by default', async () => {
  await assertFails(setDoc(doc(env.authenticatedContext('root').firestore(), 'misc/x'), { a: 1 }));
});
test('R-05 user creates own profile with role user (first sign-in)', async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/bob'), { role: 'user', displayName: 'Bob' }));
});
test('R-06 user cannot create own profile as admin or for someone else', async () => {
  const db = env.authenticatedContext('carol').firestore();
  await assertFails(setDoc(doc(db, 'users/carol'), { role: 'admin' }));
  await assertFails(setDoc(doc(db, 'users/dave'), { role: 'user' }));
});

const note = (extra = {}) => ({
  type: 'chien_thang',
  title: 'Dọn bàn học',
  mood: 'on',
  createdAt: Timestamp.now(),
  ...extra,
});

test('R-07 user writes, reads and deletes own notes', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice/notes/n1'), note({ body: 'Nhẹ hơn hôm qua.' })));
  await assertSucceeds(getDoc(doc(db, 'users/alice/notes/n1')));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/notes/n1')));
});
test("R-08 user cannot read or write someone else's notes", async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(setDoc(doc(db, 'users/alice/notes/n2'), note()));
  await assertFails(getDoc(doc(db, 'users/alice/notes/n1')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice/notes/n1')));
});
test('R-09 invalid notes are rejected', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'users/alice/notes/x1'), note({ title: '' })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/x2'), note({ title: 'a'.repeat(121) })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/x3'), note({ body: 'a'.repeat(2001) })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/x4'), note({ type: 'spam' })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/x5'), note({ mood: 'angry' })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/x6'), note({ extra: true })));
});
test('R-10 user saves own month sticker only under its own id', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice/stickers/2026-10'), { month: '2026-10' }));
  await assertFails(setDoc(doc(db, 'users/alice/stickers/2026-11'), { month: '2026-10' }));
  await assertFails(setDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/stickers/2026-12'), { month: '2026-12' }));
});
test('R-11 user keeps private habits and settings; others cannot read them', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice/private/habits'), { selected: ['Video ngắn'], custom: [] }));
  await assertSucceeds(setDoc(doc(db, 'users/alice/private/settings'), { awakeEnabled: true, awakeStart: 1380, awakeEnd: 60, lockSelfControl: false }));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/private/habits')));
  await assertFails(setDoc(doc(db, 'users/alice/private/habits'), { selected: [], role: 'admin' }));
  await assertFails(setDoc(doc(db, 'users/alice/private/other'), { a: 1 }));
});
test('R-12 challenge catalog is read-only; progress is private', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'challenges/dc-1-1'), { topic: 'dung_cam', level: 1, order: 1, title: 'Chào bác bảo vệ', minutes: 1 });
  });
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(getDoc(doc(db, 'challenges/dc-1-1')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'challenges/dc-1-1')));
  await assertFails(setDoc(doc(db, 'challenges/dc-9-9'), { title: 'x' }));
  await assertSucceeds(setDoc(doc(db, 'users/alice/challengeProgress/dung_cam'), { level: 1, completed: ['dc-1-1'] }));
  await assertFails(setDoc(doc(db, 'users/alice/challengeProgress/other'), { level: 1, completed: [] }));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/challengeProgress/dung_cam')));
});
test('R-13 challenge notes keep their result fields within range', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const result = { challengeId: 'dc-1-1', subtype: 'nguoi_la', outcome: 'khong_nhu_y', anxietyBefore: 4 };
  await assertSucceeds(setDoc(doc(db, 'users/alice/notes/c1'), note({ type: 'thu_thach', ...result })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/c2'), note({ type: 'thu_thach', ...result, anxietyBefore: 9 })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/c3'), note({ type: 'thu_thach', ...result, outcome: 'win' })));
});
test('R-14 user keeps "first time" groups; names and ideas are checked', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const group = (extra = {}) => ({ name: 'Bắt chuyện', idea: 'nguoi_la', source: 'system', noteCount: 0, ...extra });
  await assertSucceeds(setDoc(doc(db, 'users/alice/groups/bat-chuyen'), group()));
  await assertSucceeds(updateDoc(doc(db, 'users/alice/groups/bat-chuyen'), { noteCount: 1, firstNoteId: 'n1', firstNoteTitle: 'Hỏi đường', firstAt: Timestamp.now() }));
  await assertFails(setDoc(doc(db, 'users/alice/groups/g2'), group({ name: '' })));
  await assertFails(setDoc(doc(db, 'users/alice/groups/g3'), group({ name: 'a'.repeat(25) })));
  await assertFails(setDoc(doc(db, 'users/alice/groups/g4'), group({ idea: 'spam' })));
  await assertFails(setDoc(doc(db, 'users/alice/groups/g5'), group({ extra: true })));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/groups/bat-chuyen')));
  await assertSucceeds(setDoc(doc(db, 'users/alice/notes/g1'), note({ groupId: 'bat-chuyen', isFirst: true })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/g2'), note({ groupId: '', isFirst: true })));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/groups/bat-chuyen')));
});
