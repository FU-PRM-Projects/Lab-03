const { test, before, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, getDocs, setDoc, addDoc, updateDoc, deleteDoc, deleteField, Timestamp, serverTimestamp,
  collection, query, where,
} = require('firebase/firestore');

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
    await setDoc(doc(db, 'users/gina'), { role: 'user' });
    await setDoc(doc(db, 'users/sam'), { role: 'staff' });
    await setDoc(doc(db, 'users/uma'), { role: 'user' });
  });
});
after(() => env.cleanup());

test('R-01 user cannot change own role', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(updateDoc(doc(db, 'users/alice'), { role: 'admin' }));
});
test('R-02 admin can change a role', async () => {
  const db = env.authenticatedContext('root').firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/gina'), { role: 'staff' }));
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

// ---- Final Assignment: staff role, catalog, submissions, inbox, announcements ----

const stamp = (uid) => ({ updatedBy: uid, updatedAt: serverTimestamp() });
const card = (extra = {}) => ({
  topic: 'dung_cam', level: 1, order: 9, title: 'Hỏi giờ một người lạ', minutes: 2, status: 'active', ...stamp('sam'), ...extra,
});
const submission = (uid, extra = {}) => ({
  uid, topic: 'van_dong', title: 'Đi cầu thang thay thang máy', minutes: 5, status: 'pending', createdAt: serverTimestamp(), ...extra,
});

test('R-19 staff create, edit and archive catalog cards; users and bad cards are denied', async () => {
  const staff = env.authenticatedContext('sam').firestore();
  const user = env.authenticatedContext('uma').firestore();
  await assertSucceeds(setDoc(doc(staff, 'challenges/st-1'), card({ source: 'staff' })));
  await assertSucceeds(updateDoc(doc(staff, 'challenges/st-1'), { title: 'Hỏi đường một người lạ', ...stamp('sam') }));
  await assertSucceeds(updateDoc(doc(staff, 'challenges/st-1'), { status: 'archived', ...stamp('sam') }));
  await assertFails(updateDoc(doc(staff, 'challenges/st-1'), { status: 'active' }));
  await assertFails(deleteDoc(doc(staff, 'challenges/st-1')));
  await assertFails(setDoc(doc(user, 'challenges/st-2'), card(stamp('uma'))));
  await assertFails(updateDoc(doc(user, 'challenges/st-1'), { status: 'active', ...stamp('uma') }));
  await assertFails(setDoc(doc(staff, 'challenges/st-3'), card({ status: 'deleted' })));
  await assertFails(setDoc(doc(staff, 'challenges/st-4'), card({ title: '' })));
  await assertFails(setDoc(doc(staff, 'challenges/st-5'), card({ updatedBy: 'someone-else' })));
});

test('R-20 user submits a pending card for themselves only', async () => {
  const user = env.authenticatedContext('uma').firestore();
  await assertSucceeds(setDoc(doc(user, 'challengeSubmissions/s1'), submission('uma', { tip: 'Từ tầng 3 trở xuống' })));
  await assertFails(setDoc(doc(user, 'challengeSubmissions/s2'), submission('uma', { status: 'approved' })));
  await assertFails(setDoc(doc(user, 'challengeSubmissions/s3'), submission('alice')));
  await assertFails(setDoc(doc(user, 'challengeSubmissions/s4'), submission('uma', { title: 'a'.repeat(81) })));
  await assertFails(setDoc(doc(user, 'challengeSubmissions/s5'), submission('uma', { createdAt: Timestamp.fromMillis(0) })));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'challengeSubmissions/s6'), submission('uma')));
});

test('R-21 owner and staff read a submission; other users do not', async () => {
  await assertSucceeds(getDoc(doc(env.authenticatedContext('uma').firestore(), 'challengeSubmissions/s1')));
  await assertSucceeds(getDoc(doc(env.authenticatedContext('sam').firestore(), 'challengeSubmissions/s1')));
  await assertSucceeds(getDocs(query(collection(env.authenticatedContext('uma').firestore(), 'challengeSubmissions'), where('uid', '==', 'uma'))));
  await assertSucceeds(getDocs(query(collection(env.authenticatedContext('sam').firestore(), 'challengeSubmissions'), where('status', '==', 'pending'))));
  await assertFails(getDoc(doc(env.authenticatedContext('alice').firestore(), 'challengeSubmissions/s1')));
  await assertFails(getDocs(query(collection(env.authenticatedContext('uma').firestore(), 'challengeSubmissions'), where('status', '==', 'pending'))));
});

test('R-22 only staff move pending to approved or rejected; a rejection needs a reason', async () => {
  const staff = env.authenticatedContext('sam').firestore();
  const user = env.authenticatedContext('uma').firestore();
  await assertSucceeds(setDoc(doc(user, 'challengeSubmissions/s7'), submission('uma')));
  await assertSucceeds(setDoc(doc(user, 'challengeSubmissions/s8'), submission('uma')));
  const review = (status, reason) => ({ status, reason, reviewedBy: 'sam', reviewedAt: serverTimestamp() });
  await assertFails(updateDoc(doc(user, 'challengeSubmissions/s1'), review('approved', '')));
  await assertFails(updateDoc(doc(staff, 'challengeSubmissions/s7'), review('rejected', '')));
  await assertFails(updateDoc(doc(staff, 'challengeSubmissions/s7'), { ...review('approved', ''), title: 'Đổi tên' }));
  await assertFails(updateDoc(doc(staff, 'challengeSubmissions/s7'), { ...review('approved', ''), reviewedBy: 'root' }));
  await assertSucceeds(updateDoc(doc(staff, 'challengeSubmissions/s7'), { ...review('approved', ''), challengeId: 'cm-s7' }));
  await assertSucceeds(updateDoc(doc(staff, 'challengeSubmissions/s8'), review('rejected', 'Trùng với thẻ có sẵn')));
  // Reviewed items are final.
  await assertFails(updateDoc(doc(staff, 'challengeSubmissions/s8'), review('approved', '')));
});

test('R-23 owner withdraws a pending submission but not a reviewed one', async () => {
  const user = env.authenticatedContext('uma').firestore();
  await assertFails(deleteDoc(doc(env.authenticatedContext('alice').firestore(), 'challengeSubmissions/s1')));
  await assertSucceeds(deleteDoc(doc(user, 'challengeSubmissions/s1')));
  await assertFails(deleteDoc(doc(user, 'challengeSubmissions/s8')));
});

test('R-24 staff write inbox messages; the owner reads and marks them read', async () => {
  const staff = env.authenticatedContext('sam').firestore();
  const user = env.authenticatedContext('uma').firestore();
  const message = (extra = {}) => ({
    kind: 'submission_approved', title: 'Thẻ của bạn đã được duyệt', body: 'Đi cầu thang thay thang máy', read: false,
    submissionId: 's7', createdAt: serverTimestamp(), ...extra,
  });
  await assertSucceeds(setDoc(doc(staff, 'users/uma/inbox/m1'), message()));
  await assertFails(setDoc(doc(user, 'users/uma/inbox/m2'), message()));
  await assertFails(setDoc(doc(staff, 'users/uma/inbox/m3'), message({ kind: 'spam' })));
  await assertSucceeds(getDoc(doc(user, 'users/uma/inbox/m1')));
  await assertFails(getDoc(doc(staff, 'users/uma/inbox/m1')));
  await assertSucceeds(updateDoc(doc(user, 'users/uma/inbox/m1'), { read: true }));
  await assertFails(updateDoc(doc(user, 'users/uma/inbox/m1'), { title: 'Sửa' }));
  await assertSucceeds(deleteDoc(doc(user, 'users/uma/inbox/m1')));
});

test('R-25 staff post announcements that every signed-in user reads', async () => {
  const staff = env.authenticatedContext('sam').firestore();
  const user = env.authenticatedContext('uma').firestore();
  const post = (extra = {}) => ({ title: 'Thẻ mới tuần này', body: 'Có 3 thẻ vận động mới.', authorUid: 'sam', createdAt: serverTimestamp(), ...extra });
  await assertSucceeds(setDoc(doc(staff, 'announcements/a1'), post()));
  await assertSucceeds(getDoc(doc(user, 'announcements/a1')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'announcements/a1')));
  await assertFails(setDoc(doc(user, 'announcements/a2'), post({ authorUid: 'uma' })));
  await assertFails(setDoc(doc(staff, 'announcements/a3'), post({ authorUid: 'root' })));
  await assertFails(setDoc(doc(staff, 'announcements/a4'), post({ body: '' })));
  await assertFails(updateDoc(doc(staff, 'announcements/a1'), { title: 'Sửa' }));
  await assertFails(deleteDoc(doc(user, 'announcements/a1')));
  await assertSucceeds(deleteDoc(doc(staff, 'announcements/a1')));
});

test('R-26 staff read user profiles; only an admin changes roles, never their own', async () => {
  await assertSucceeds(getDoc(doc(env.authenticatedContext('sam').firestore(), 'users/uma')));
  await assertFails(getDoc(doc(env.authenticatedContext('uma').firestore(), 'users/sam')));
  await assertFails(updateDoc(doc(env.authenticatedContext('sam').firestore(), 'users/uma'), { role: 'staff' }));
  await assertFails(updateDoc(doc(env.authenticatedContext('sam').firestore(), 'users/sam'), { role: 'admin' }));
  await assertFails(updateDoc(doc(env.authenticatedContext('root').firestore(), 'users/root'), { role: 'user' }));
  await assertFails(updateDoc(doc(env.authenticatedContext('root').firestore(), 'users/uma'), { role: 'owner' }));
});

test('R-27 onboarding answers are private and limited to known values', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const answers = (extra = {}) => ({
    strangerLevel: 2, habits: ['Video ngắn'], move: 'it_khi', freeSlot: 'toi', goals: ['bot_ngai'],
    profileLabel: 'Người mới tập bắt chuyện', planSource: 'rules', done: true, completedAt: serverTimestamp(), ...extra,
  });
  await assertSucceeds(setDoc(doc(alice, 'users/alice/private/onboarding'), answers()));
  await assertSucceeds(setDoc(doc(alice, 'users/alice/private/onboarding'), answers({ strangerLevel: null, move: null, goals: [] })));
  await assertSucceeds(getDoc(doc(alice, 'users/alice/private/onboarding')));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/private/onboarding')));
  await assertFails(setDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/private/onboarding'), answers()));
  await assertFails(setDoc(doc(alice, 'users/alice/private/onboarding'), answers({ strangerLevel: 9 })));
  await assertFails(setDoc(doc(alice, 'users/alice/private/onboarding'), answers({ goals: ['a', 'b', 'c'] })));
  await assertFails(setDoc(doc(alice, 'users/alice/private/onboarding'), answers({ move: 'bay' })));
  await assertFails(setDoc(doc(alice, 'users/alice/private/onboarding'), answers({ email: 'a@b.c' })));
});

test('R-28 owner saves weekly card PDF metadata; the shape must match the week', async () => {
  const owner = env.authenticatedContext('uma').firestore();
  const other = env.authenticatedContext('olga').firestore();
  const report = (extra = {}) => ({
    kind: 'weekly_card', isoWeek: '2026-W46', fileName: 'weekly-2026-W46.pdf', sizeBytes: 34120, noteCount: 5,
    savedAt: serverTimestamp(), ...extra,
  });
  await assertSucceeds(setDoc(doc(owner, 'users/uma/reports/2026-W46'), report()));
  await assertSucceeds(setDoc(doc(owner, 'users/uma/reports/2026-W46'), report({ sizeBytes: 35000 })));
  await assertSucceeds(getDoc(doc(owner, 'users/uma/reports/2026-W46')));
  await assertFails(getDoc(doc(other, 'users/uma/reports/2026-W46')));
  await assertFails(setDoc(doc(other, 'users/uma/reports/2026-W47'), report({ isoWeek: '2026-W47', fileName: 'weekly-2026-W47.pdf' })));
  await assertFails(setDoc(doc(owner, 'users/uma/reports/2026-W47'), report()));
  await assertFails(setDoc(doc(owner, 'users/uma/reports/2026-W46'), report({ fileName: 'other.pdf' })));
  await assertFails(setDoc(doc(owner, 'users/uma/reports/2026-W46'), report({ sizeBytes: 0 })));
  await assertFails(setDoc(doc(owner, 'users/uma/reports/2026-W46'), report({ url: 'https://example.com/a.pdf' })));
  await assertFails(setDoc(doc(owner, 'users/uma/reports/2026-W46'), report({ savedAt: Timestamp.fromDate(new Date('2020-01-01')) })));
  await assertSucceeds(deleteDoc(doc(owner, 'users/uma/reports/2026-W46')));
});

