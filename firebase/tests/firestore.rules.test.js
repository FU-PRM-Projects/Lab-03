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
