const { test, before, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, deleteField, Timestamp } = require('firebase/firestore');

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
test('R-15 user adds and deletes their own challenge cards, privately', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const card = (extra = {}) => ({ topic: 'dung_cam', title: 'Nhắn lời cảm ơn', minutes: 2, createdAt: Timestamp.now(), ...extra });
  await assertSucceeds(setDoc(doc(db, 'users/alice/customChallenges/c1'), card()));
  await assertSucceeds(setDoc(doc(db, 'users/alice/customChallenges/c2'), card({ topic: 'van_dong', tip: 'Đi chậm thôi.' })));
  await assertFails(setDoc(doc(db, 'users/alice/customChallenges/c3'), card({ title: '' })));
  await assertFails(setDoc(doc(db, 'users/alice/customChallenges/c4'), card({ title: 'a'.repeat(81) })));
  await assertFails(setDoc(doc(db, 'users/alice/customChallenges/c5'), card({ topic: 'spam' })));
  await assertFails(setDoc(doc(db, 'users/alice/customChallenges/c6'), card({ minutes: 0 })));
  await assertFails(setDoc(doc(db, 'users/alice/customChallenges/c7'), card({ minutes: 601 })));
  await assertFails(setDoc(doc(db, 'users/alice/customChallenges/c8'), card({ tip: 'a'.repeat(121) })));
  await assertFails(setDoc(doc(db, 'users/alice/customChallenges/c9'), card({ extra: true })));
  await assertFails(updateDoc(doc(db, 'users/alice/customChallenges/c1'), { title: 'Đổi tên' }));
  await assertFails(setDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/customChallenges/c10'), card()));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/customChallenges/c1')));
  await assertSucceeds(getDoc(doc(db, 'users/alice/customChallenges/c1')));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/customChallenges/c1')));
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

// Images uploaded to Cloudinary are stored as an ImageRef { url, publicId }.
const image = (extra = {}) => ({
  url: 'https://res.cloudinary.com/t7crbqj0/image/upload/v1/not/notes/abc123.jpg',
  publicId: 'not/notes/abc123',
  ...extra,
});

test('R-16 notes may carry a Cloudinary image; other images are rejected', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice/notes/i1'), note({ image: image() })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/i2'), note({ image: image({ url: 'https://evil.example/x.jpg' }) })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/i3'), note({ image: image({ extra: 1 }) })));
  await assertFails(setDoc(doc(db, 'users/alice/notes/i4'), note({ image: 'https://res.cloudinary.com/x.jpg' })));
  await assertFails(setDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/notes/i5'), note({ image: image() })));
});
test('R-17 groups may carry a Cloudinary image', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const group = (extra = {}) => ({ name: 'Leo núi', idea: 'van_dong', source: 'user', noteCount: 0, ...extra });
  await assertSucceeds(setDoc(doc(db, 'users/alice/groups/leo-nui'), group({ image: image({ publicId: 'not/groups/g1' }) })));
  await assertFails(setDoc(doc(db, 'users/alice/groups/leo-nui-2'), group({ image: image({ publicId: '' }) })));
});
test('R-18 owner sets and removes own profile photo, but cannot touch role or others', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'users/erin'), { role: 'user' }));
  const erin = env.authenticatedContext('erin').firestore();
  const photo = image({ publicId: 'not/avatars/p1' });
  await assertSucceeds(updateDoc(doc(erin, 'users/erin'), { photo }));
  await assertSucceeds(updateDoc(doc(erin, 'users/erin'), { photo: deleteField() }));
  await assertFails(updateDoc(doc(erin, 'users/erin'), { photo, role: 'admin' }));
  await assertFails(updateDoc(doc(erin, 'users/erin'), { photo: image({ url: 'http://res.cloudinary.com/x.jpg' }) }));
  await assertFails(updateDoc(doc(alice, 'users/erin'), { photo }));
  // First sign-in failed earlier: the app creates the profile with the photo.
  const frank = env.authenticatedContext('frank').firestore();
  await assertSucceeds(setDoc(doc(frank, 'users/frank'), { role: 'user', photo }));
});
